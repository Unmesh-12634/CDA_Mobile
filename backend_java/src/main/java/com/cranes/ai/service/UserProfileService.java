package com.cranes.ai.service;

import com.cranes.ai.model.UserProfileDto;
import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.Optional;

@Service
public class UserProfileService {

    private final OkHttpClient httpClient;
    private final ObjectMapper objectMapper;

    @Value("${supabase.url:https://jbauuvxeybakihedeskj.supabase.co}")
    private String supabaseUrl;

    @Value("${supabase.anon-key:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiYXV1dnhleWJha2loZWRlc2tqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5MDMxNTgsImV4cCI6MjEwMDQ3OTE1OH0.FBLtZxjOt8UG-W1vUw67V43D3mB22UhPBKSltqj2dTg}")
    private String supabaseKey;

    public UserProfileService() {
        this.httpClient = new OkHttpClient();
        this.objectMapper = new ObjectMapper();
    }

    public Optional<UserProfileDto> getProfileByEmail(String email) {
        String url = supabaseUrl + "/rest/v1/users?email=eq." + email + "&limit=1";
        Request request = new Request.Builder()
                .url(url)
                .addHeader("apikey", supabaseKey)
                .addHeader("Authorization", "Bearer " + supabaseKey)
                .get()
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            if (response.isSuccessful() && response.body() != null) {
                String bodyStr = response.body().string();
                UserProfileDto[] profiles = objectMapper.readValue(bodyStr, UserProfileDto[].class);
                if (profiles.length > 0) {
                    return Optional.of(profiles[0]);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return Optional.empty();
    }

    public boolean updateProfile(String email, UserProfileDto profileDto) {
        String url = supabaseUrl + "/rest/v1/users?email=eq." + email;
        try {
            String jsonPayload = objectMapper.writeValueAsString(profileDto);
            RequestBody body = RequestBody.create(jsonPayload, MediaType.get("application/json; charset=utf-8"));

            Request request = new Request.Builder()
                    .url(url)
                    .addHeader("apikey", supabaseKey)
                    .addHeader("Authorization", "Bearer " + supabaseKey)
                    .addHeader("Prefer", "return=representation")
                    .patch(body)
                    .build();

            try (Response response = httpClient.newCall(request).execute()) {
                return response.isSuccessful();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }
}
