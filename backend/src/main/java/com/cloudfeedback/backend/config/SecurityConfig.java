package com.cloudfeedback.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
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

        @Bean
        public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

                http
                                .csrf(csrf -> csrf.disable())
                                .headers(headers -> headers.frameOptions(frame -> frame.disable()))

                                .authorizeHttpRequests(auth -> auth

                                                // Öffentliches Feedbackformular
                                                .requestMatchers(HttpMethod.POST, "/api/feedback").permitAll()

                                                // Admin APIs
                                                .requestMatchers(HttpMethod.GET, "/api/feedback").hasAuthority("ROLE_ADMIN")
                                                .requestMatchers(HttpMethod.GET, "/api/feedback/stats").hasAuthority("ROLE_ADMIN")

                                                // Actuator
                                                .requestMatchers("/actuator/**").permitAll()

                                                // H2 Console
                                                .requestMatchers("/h2-console/**").permitAll()

                                                .anyRequest().permitAll())

                                .oauth2ResourceServer(oauth2 -> oauth2
                                                .jwt(jwt -> jwt.jwtAuthenticationConverter(
                                                                jwtAuthenticationConverter())));

                return http.build();
        }

        private Converter<Jwt, ? extends AbstractAuthenticationToken> jwtAuthenticationConverter() {

                JwtGrantedAuthoritiesConverter gac = new JwtGrantedAuthoritiesConverter();
                gac.setAuthoritiesClaimName("cognito:groups");

                // Kein Präfix hinzufügen – Cognito liefert bereits ROLE_ADMIN
                gac.setAuthorityPrefix("");

                JwtAuthenticationConverter jac = new JwtAuthenticationConverter();
                jac.setJwtGrantedAuthoritiesConverter(gac);

                return jac;
        }
}