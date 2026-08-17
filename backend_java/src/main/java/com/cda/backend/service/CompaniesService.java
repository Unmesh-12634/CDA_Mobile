package com.cda.backend.service;

import com.cda.backend.dao.CompaniesDAO;
import com.cda.backend.model.Company;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CompaniesService {

    @Autowired
    private CompaniesDAO companiesDAO;

    public List<Company> getAllCompanies() {
        return companiesDAO.findAllActive();
    }

    public Company getById(String id) {
        return companiesDAO.findById(id);
    }
}
