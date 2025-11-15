package com.netportscanner.bo;

import java.util.Optional;

import com.netportscanner.bean.User;
import com.netportscanner.dao.UserDAO;

public class AuthBO {
private UserDAO userDAO;
    
    public AuthBO() {
        this.userDAO = new UserDAO();
    }
    
    public boolean register(String username, String email, String password) {
        // Validate input
        if (username == null || username.trim().isEmpty() || 
            email == null || email.trim().isEmpty() || 
            password == null || password.length() < 6) {
            return false;
        }
        
        // Check if user already exists
        if (userDAO.findByUsername(username).isPresent() || 
            userDAO.findByEmail(email).isPresent()) {
            return false;
        }
        
        // Create new user
        String hashedPassword = userDAO.hashPassword(password);
        User user = new User(username.trim(), email.trim(), hashedPassword);
        
        return userDAO.createUser(user);
    }
    
    public Optional<User> login(String username, String password) {
        Optional<User> userOpt = userDAO.findByUsername(username);
        
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            if (userDAO.verifyPassword(password, user.getPasswordHash())) {
                return Optional.of(user);
            }
        }
        
        return Optional.empty();
    }
}
