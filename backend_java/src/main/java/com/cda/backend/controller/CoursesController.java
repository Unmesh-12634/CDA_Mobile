package com.cda.backend.controller;

import com.cda.backend.dto.ApiResponse;
import com.cda.backend.model.Course;
import com.cda.backend.service.CoursesService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/api/v1/courses")
@CrossOrigin(origins = "*")
public class CoursesController {

    @Autowired
    private CoursesService coursesService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Course>>> getAllCourses(
            @RequestParam(required = false) String category) {
        List<Course> list = coursesService.getAllCourses(category);
        return ResponseEntity.ok(ApiResponse.ok(list, "Courses retrieved successfully"));
    }

    @GetMapping("/featured")
    public ResponseEntity<ApiResponse<List<Course>>> getFeaturedCourses() {
        List<Course> list = coursesService.getFeaturedCourses();
        return ResponseEntity.ok(ApiResponse.ok(list, "Featured courses retrieved successfully"));
    }

    @GetMapping("/recommend")
    public ResponseEntity<ApiResponse<List<Course>>> getRecommendedCourses(
            @RequestParam(required = false) String skills) {
        List<String> skillList = skills != null && !skills.trim().isEmpty()
                ? Arrays.asList(skills.split(","))
                : null;
        List<Course> list = coursesService.getRecommendedCourses(skillList);
        return ResponseEntity.ok(ApiResponse.ok(list, "Recommended courses retrieved successfully"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Course>> getCourseById(@PathVariable String id) {
        Course course = coursesService.getCourseById(id);
        if (course == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(ApiResponse.ok(course, "Course retrieved successfully"));
    }
}
