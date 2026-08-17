package com.cda.backend.model;

import java.util.List;

public class Job {
    private String id;
    private String title;
    private String company;
    private String companyLogoUrl;
    private String companyWebsite;
    private String companyIndustry;
    private String location;
    private String type;
    private String salary;
    private String logoText;
    private String category;
    private Integer matchScore;
    private String postedAgo;
    private String experienceLevel;
    private String description;
    private List<String> responsibilities;
    private List<String> requirements;
    private List<String> tags;

    public Job() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getCompany() { return company; }
    public void setCompany(String company) { this.company = company; }

    public String getCompanyLogoUrl() { return companyLogoUrl; }
    public void setCompanyLogoUrl(String companyLogoUrl) { this.companyLogoUrl = companyLogoUrl; }

    public String getCompanyWebsite() { return companyWebsite; }
    public void setCompanyWebsite(String companyWebsite) { this.companyWebsite = companyWebsite; }

    public String getCompanyIndustry() { return companyIndustry; }
    public void setCompanyIndustry(String companyIndustry) { this.companyIndustry = companyIndustry; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getSalary() { return salary; }
    public void setSalary(String salary) { this.salary = salary; }

    public String getLogoText() { return logoText; }
    public void setLogoText(String logoText) { this.logoText = logoText; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public Integer getMatchScore() { return matchScore; }
    public void setMatchScore(Integer matchScore) { this.matchScore = matchScore; }

    public String getPostedAgo() { return postedAgo; }
    public void setPostedAgo(String postedAgo) { this.postedAgo = postedAgo; }

    public String getExperienceLevel() { return experienceLevel; }
    public void setExperienceLevel(String experienceLevel) { this.experienceLevel = experienceLevel; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public List<String> getResponsibilities() { return responsibilities; }
    public void setResponsibilities(List<String> responsibilities) { this.responsibilities = responsibilities; }

    public List<String> getRequirements() { return requirements; }
    public void setRequirements(List<String> requirements) { this.requirements = requirements; }

    public List<String> getTags() { return tags; }
    public void setTags(List<String> tags) { this.tags = tags; }
}
