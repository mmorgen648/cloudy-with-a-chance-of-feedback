package com.cloudfeedback.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.core.convert.converter.Converter;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

        /**
         * 1️⃣ Actuator – öffentlich
         */
        @Bean
        @Order(1)
        public SecurityFilterChain actuatorSecurity(HttpSecurity http) throws Exception {

                http
                                .securityMatcher("/actuator/**")
                                .csrf(csrf -> csrf.disable())
                                .authorizeHttpRequests(auth -> auth.anyRequest().permitAll());

                return http.build();
        }

        /**
         * 2️⃣ Public Feedback Endpoint
         * KEIN OAuth2 Filter
         */
        @Bean
        @Order(2)
        public SecurityFilterChain publicFeedbackSecurity(HttpSecurity http) throws Exception {

                http
                                .securityMatcher("/api/feedback/**")
                                .csrf(csrf -> csrf.disable())
                                .authorizeHttpRequests(auth -> auth
                                                .requestMatchers(HttpMethod.POST, "/api/feedback").permitAll()
                                                .anyRequest().denyAll());

                return http.build();
        }

        /**
         * 3️⃣ Admin API
         */
        @Bean
        @Order(3)
        public SecurityFilterChain adminApiSecurity(HttpSecurity http) throws Exception {

                http
                                .csrf(csrf -> csrf.disable())
                                .headers(headers -> headers.frameOptions(frame -> frame.disable()))

                                .authorizeHttpRequests(auth -> auth

                                                // H2 Console lokal
                                                .requestMatchers("/h2-console/**").permitAll()

                                                // Admin APIs
                                                .requestMatchers(HttpMethod.GET, "/api/feedback/stats").hasRole("ADMIN")
                                                .requestMatchers(HttpMethod.GET, "/api/feedback").hasRole("ADMIN")

                                                .anyRequest().authenticated())

                                .oauth2ResourceServer(oauth2 -> oauth2
                                                .jwt(jwt -> jwt.jwtAuthenticationConverter(
                                                                jwtAuthenticationConverter())));

                return http.build();
        }

        private Converter<Jwt, ? extends AbstractAuthenticationToken> jwtAuthenticationConverter() {

                JwtGrantedAuthoritiesConverter gac = new JwtGrantedAuthoritiesConverter();
                gac.setAuthoritiesClaimName("cognito:groups");
                gac.setAuthorityPrefix("ROLE_");

                JwtAuthenticationConverter jac = new JwtAuthenticationConverter();
                jac.setJwtGrantedAuthoritiesConverter(gac);

                return jac;
        }
}