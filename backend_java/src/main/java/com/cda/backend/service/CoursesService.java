package com.cda.backend.service;

import com.cda.backend.dao.CoursesDAO;
import com.cda.backend.model.Course;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class CoursesService {

    @Autowired
    private CoursesDAO coursesDAO;

    public List<Course> getAllCourses(String category) {
        if (category != null && !category.trim().isEmpty() && !category.equalsIgnoreCase("All")) {
            return coursesDAO.findByCategory(category);
        }
        return coursesDAO.findAllActive();
    }

    public List<Course> getFeaturedCourses() {
        return coursesDAO.findFeatured();
    }

    public Course getCourseById(String id) {
        return coursesDAO.findById(id);
    }

    public List<Course> getRecommendedCourses(List<String> skills) {
        List<Course> all = coursesDAO.findAllActive();
        if (skills == null || skills.isEmpty()) {
            return all;
        }

        List<Course> matched = new ArrayList<>();
        for (Course c : all) {
            boolean matches = false;
            for (String skill : skills) {
                String cleanSkill = skill.toLowerCase().replace("#", "").trim();
                if (c.getTitle().toLowerCase().contains(cleanSkill) ||
                    c.getCategory().toLowerCase().contains(cleanSkill) ||
                    c.getDescription().toLowerCase().contains(cleanSkill)) {
                    matches = true;
                    break;
                }
                if (c.getTags() != null) {
                    for (String tag : c.getTags()) {
                        if (tag.toLowerCase().replace("#", "").contains(cleanSkill)) {
                            matches = true;
                            break;
                        }
                    }
                }
                if (matches) break;
            }
            if (matches) {
                matched.add(c);
            }
        }
        return matched.isEmpty() ? all : matched;
    }
}
