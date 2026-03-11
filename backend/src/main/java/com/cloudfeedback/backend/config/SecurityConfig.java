package com.cloudfeedback.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.core.annotation.Order;
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
         * Security Chain für Actuator
         * → komplett ohne Auth
         */
        @Bean
        @Order(1)
        public SecurityFilterChain actuatorSecurity(HttpSecurity http) throws Exception {

                http
                                .securityMatcher("/actuator/**")
                                .csrf(csrf -> csrf.disable())
                                .authorizeHttpRequests(auth -> auth
                                                .anyRequest().permitAll());

                return http.build();
        }

        /**
         * Haupt Security für API
         */
        @Bean
        @Order(2)
        public SecurityFilterChain apiSecurity(HttpSecurity http) throws Exception {

                http
                                .csrf(csrf -> csrf.disable())

                                // H2 Console benötigt deaktivierte Frame Options
                                .headers(headers -> headers
                                                .frameOptions(frame -> frame.disable()))

                                .authorizeHttpRequests(auth -> auth

                                                // H2 Console lokal erlauben
                                                .requestMatchers("/h2-console/**").permitAll()

                                                // Öffentliches Feedbackformular (Projektanforderung)
                                                // POST /api/feedback muss öffentlich sein
                                                .requestMatchers("/api/feedback/**").permitAll()

                                                // Admin Statistik Endpoint
                                                .requestMatchers(HttpMethod.GET, "/api/feedback/stats").hasRole("ADMIN")

                                                // Lesen aller Feedbacks nur für Admin
                                                .requestMatchers(HttpMethod.GET, "/api/feedback").hasRole("ADMIN")

                                                // Alle anderen Endpoints benötigen Authentifizierung
                                                .anyRequest().authenticated())

                                // Cognito JWT Validierung
                                .oauth2ResourceServer(oauth2 -> oauth2
                                                .jwt(jwt -> jwt
                                                                .jwtAuthenticationConverter(
                                                                                jwtAuthenticationConverter())));

                return http.build();
        }

        /**
         * Konvertiert Cognito Gruppen → Spring Security Authorities
         */
        private Converter<Jwt, ? extends AbstractAuthenticationToken> jwtAuthenticationConverter() {

                JwtGrantedAuthoritiesConverter gac = new JwtGrantedAuthoritiesConverter();

                // Cognito speichert Rollen im Claim "cognito:groups"
                gac.setAuthoritiesClaimName("cognito:groups");

                // Wichtig: Spring erwartet ROLE_ Prefix
                gac.setAuthorityPrefix("ROLE_");

                JwtAuthenticationConverter jac = new JwtAuthenticationConverter();
                jac.setJwtGrantedAuthoritiesConverter(gac);

                return jac;
        }
}