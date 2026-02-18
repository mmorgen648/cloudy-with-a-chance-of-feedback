package com.cloudfeedback.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

/**
 * SecurityConfig
 *
 * Lokal:
 * - Erlaubt alle Requests
 * - Aktiviert H2 Console
 */
@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {

        http
            // CSRF deaktivieren (für REST ok + H2 nötig)
            .csrf(csrf -> csrf.disable())

            // H2 Console braucht Frames
            .headers(headers -> headers
                .frameOptions(frame -> frame.disable())
            )

            // Alles erlauben
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll()
            )

            .formLogin(form -> form.disable());

        return http.build();
    }
}
