package com.cda.backend.service;

import com.cda.backend.dao.UserProfileDAO;
import com.cda.backend.dto.ProfileAnalyticsDTO;
import com.cda.backend.exception.BusinessException;
import com.cda.backend.exception.ResourceNotFoundException;
import com.cda.backend.model.UserProfile;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class UserProfileService {

    @Autowired
    private UserProfileDAO userProfileDAO;

    public UserProfile getProfileByEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            throw new BusinessException("Email address must not be empty.");
        }
        UserProfile profile = userProfileDAO.findByEmail(email.trim());
        if (profile == null) {
            throw new ResourceNotFoundException("User profile not found for email: " + email);
        }
        return profile;
    }

    public UserProfile saveOrUpdateProfile(UserProfile profile) {
        if (profile.getEmail() == null || profile.getEmail().trim().isEmpty()) {
            throw new BusinessException("Email is required to save profile.");
        }
        boolean success = userProfileDAO.saveOrUpdate(profile);
        if (!success) {
            throw new BusinessException("Database update failed for user: " + profile.getEmail());
        }
        return userProfileDAO.findByEmail(profile.getEmail());
    }

    /**
     * Enterprise Java Business Logic: Calculate Profile Strength & AI Domain Affinities
     */
    public ProfileAnalyticsDTO getProfileAnalytics(String email) {
        UserProfile profile = userProfileDAO.findByEmail(email != null ? email.trim() : "unii12634@gmail.com");
        if (profile == null) {
            profile = new UserProfile();
            profile.setEmail(email);
        }

        ProfileAnalyticsDTO dto = new ProfileAnalyticsDTO();
        List<String> missing = new ArrayList<>();
        double score = 0.0;

        // 1. Full name
        if (profile.getFullName() != null && !profile.getFullName().trim().isEmpty()) {
            score += 0.10;
        } else {
            missing.add("Full Name");
        }

        // 2. Email
        if (profile.getEmail() != null && !profile.getEmail().trim().isEmpty()) {
            score += 0.10;
        }

        // 3. Phone
        if (profile.getPhone() != null && !profile.getPhone().trim().isEmpty()) {
            score += 0.10;
        } else {
            missing.add("Phone Number");
        }

        // 4. Academics
        int academicPts = 0;
        if (profile.getDegree() != null && !profile.getDegree().trim().isEmpty()) academicPts++;
        if (profile.getBranch() != null && !profile.getBranch().trim().isEmpty()) academicPts++;
        if (profile.getPassingYear() != null && !profile.getPassingYear().trim().isEmpty()) academicPts++;
        score += (academicPts / 3.0) * 0.15;
        if (academicPts < 3) missing.add("College / Degree details");

        // 5. Resume / CV
        if (profile.getResumeUrl() != null && !profile.getResumeUrl().trim().isEmpty()) {
            score += 0.20;
        } else {
            missing.add("Verified Resume");
        }

        // 6. Social Links
        int socialPts = 0;
        if (profile.getGithubUrl() != null && !profile.getGithubUrl().trim().isEmpty()) socialPts++;
        if (profile.getLinkedinUrl() != null && !profile.getLinkedinUrl().trim().isEmpty()) socialPts++;
        if (profile.getPortfolioUrl() != null && !profile.getPortfolioUrl().trim().isEmpty()) socialPts++;
        score += (socialPts >= 2 ? 0.15 : (socialPts == 1 ? 0.08 : 0.0));
        if (socialPts == 0) missing.add("GitHub / LinkedIn profiles");

        // 7. Skills
        if (profile.getSkills() != null && !profile.getSkills().isEmpty()) {
            score += (profile.getSkills().size() >= 3 ? 0.10 : 0.05);
        } else {
            missing.add("Core Technical Skills");
        }

        // 8. Experience
        if (profile.getExperienceYears() != null && profile.getExperienceYears() > 0) {
            score += 0.10;
        }

        int percentage = (int) Math.min(100, Math.round(score * 100));
        dto.setProfileStrengthPercentage(percentage);
        dto.setMissingFields(missing);

        if (missing.contains("Verified Resume")) {
            dto.setStrengthHint("Upload your verified resume to reach +20% strength");
        } else if (missing.contains("GitHub / LinkedIn profiles")) {
            dto.setStrengthHint("Add GitHub / LinkedIn links to boost strength");
        } else if (percentage >= 95) {
            dto.setStrengthHint("🎉 All-Star Profile Complete (100%)");
        } else {
            dto.setStrengthHint("Complete remaining fields to reach 100%");
        }

        // Calculate Real Dynamic Domain Match Scores
        Map<String, Double> allDomainScores = new HashMap<>();
        List<String> userSkills = profile.getSkills() != null ? profile.getSkills() : List.of();
        String role = (profile.getTargetRole() != null ? profile.getTargetRole() : "").toLowerCase();

        // 1. Enterprise Java & Backend
        double javaScore = 0.45;
        for (String s : userSkills) {
            String sl = s.toLowerCase();
            if (sl.contains("java") || sl.contains("spring") || sl.contains("microservices") || sl.contains("hibernate") || sl.contains("sql") || sl.contains("maven")) javaScore += 0.15;
        }
        if (role.contains("java") || role.contains("backend") || role.contains("software")) javaScore += 0.20;
        allDomainScores.put("Java & Enterprise Backend", Math.min(0.98, javaScore));

        // 2. Mobile App Development
        double mobileScore = 0.40;
        for (String s : userSkills) {
            String sl = s.toLowerCase();
            if (sl.contains("flutter") || sl.contains("dart") || sl.contains("android") || sl.contains("ios") || sl.contains("react native") || sl.contains("mobile")) mobileScore += 0.18;
        }
        if (role.contains("flutter") || role.contains("mobile") || role.contains("android") || role.contains("ios")) mobileScore += 0.20;
        allDomainScores.put("Mobile App Engineering", Math.min(0.98, mobileScore));

        // 3. AI, ML & Data Science
        double aiScore = 0.35;
        for (String s : userSkills) {
            String sl = s.toLowerCase();
            if (sl.contains("python") || sl.contains("machine learning") || sl.contains("ai") || sl.contains("data") || sl.contains("deep learning") || sl.contains("tensorflow") || sl.contains("pytorch") || sl.contains("pandas")) aiScore += 0.16;
        }
        if (role.contains("ai") || role.contains("data") || role.contains("ml") || role.contains("python")) aiScore += 0.20;
        allDomainScores.put("AI, ML & Data Intelligence", Math.min(0.98, aiScore));

        // 4. Cloud & DevOps Engineering
        double cloudScore = 0.30;
        for (String s : userSkills) {
            String sl = s.toLowerCase();
            if (sl.contains("aws") || sl.contains("cloud") || sl.contains("docker") || sl.contains("kubernetes") || sl.contains("devops") || sl.contains("ci/cd") || sl.contains("linux") || sl.contains("terraform")) cloudScore += 0.18;
        }
        if (role.contains("cloud") || role.contains("devops") || role.contains("sre")) cloudScore += 0.20;
        allDomainScores.put("Cloud & DevOps Architecture", Math.min(0.98, cloudScore));

        // 5. Full-Stack Web Development
        double webScore = 0.35;
        for (String s : userSkills) {
            String sl = s.toLowerCase();
            if (sl.contains("react") || sl.contains("javascript") || sl.contains("typescript") || sl.contains("node") || sl.contains("next") || sl.contains("html") || sl.contains("css") || sl.contains("tailwind")) webScore += 0.15;
        }
        if (role.contains("full stack") || role.contains("web") || role.contains("frontend")) webScore += 0.20;
        allDomainScores.put("Full-Stack Web Systems", Math.min(0.98, webScore));

        // 6. Database & Distributed Systems
        double dbScore = 0.35;
        for (String s : userSkills) {
            String sl = s.toLowerCase();
            if (sl.contains("sql") || sl.contains("postgres") || sl.contains("mysql") || sl.contains("mongodb") || sl.contains("redis") || sl.contains("kafka") || sl.contains("cassandra")) dbScore += 0.15;
        }
        allDomainScores.put("Database & Distributed Systems", Math.min(0.98, dbScore));

        // 7. Embedded Systems & IoT
        double embedScore = 0.25;
        for (String s : userSkills) {
            String sl = s.toLowerCase();
            if (sl.contains("embedded") || sl.contains("c++") || sl.contains("c") || sl.contains("iot") || sl.contains("rtos") || sl.contains("microcontroller") || sl.contains("arm")) embedScore += 0.20;
        }
        if (role.contains("embedded") || role.contains("iot")) embedScore += 0.25;
        allDomainScores.put("Embedded Systems & IoT", Math.min(0.98, embedScore));

        // 8. Cybersecurity & Penetration Testing
        double secScore = 0.25;
        for (String s : userSkills) {
            String sl = s.toLowerCase();
            if (sl.contains("security") || sl.contains("cyber") || sl.contains("owasp") || sl.contains("penetration") || sl.contains("network") || sl.contains("auth")) secScore += 0.20;
        }
        allDomainScores.put("Cybersecurity & InfoSec", Math.min(0.98, secScore));

        // Sort descending and select Top 5
        Map<String, Double> top5 = allDomainScores.entrySet().stream()
                .sorted((a, b) -> Double.compare(b.getValue(), a.getValue()))
                .limit(5)
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        e -> Math.round(e.getValue() * 100.0) / 100.0,
                        (e1, e2) -> e1,
                        LinkedHashMap::new
                ));

        dto.setTop5DomainAffinities(top5);
        return dto;
    }
}
