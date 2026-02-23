package com.cloudfeedback.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.security.web.SecurityFilterChain;

/**
 * SecurityConfig
 *
 * JWT Resource Server Configuration
 *
 * - H2 Console weiterhin lokal erlaubt
 * - /api/feedback nur für ROLE_ADMIN
 * - Alle anderen Requests benötigen gültiges JWT
 */
@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {

        http
            // CSRF deaktivieren (REST + H2)
            .csrf(csrf -> csrf.disable())

            // H2 Console braucht Frames
            .headers(headers -> headers
                .frameOptions(frame -> frame.disable())
            )

            // Authorization Regeln
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/h2-console/**").permitAll()
                .requestMatchers("/api/feedback/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )

            // OAuth2 Resource Server aktivieren (JWT + Custom Converter)
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtAuthenticationConverter(jwtAuthenticationConverter())
                )
            );

        return http.build();
    }

    /**
     * Liest cognito:groups Claim
     * Token enthält bereits ROLE_ADMIN → kein Prefix setzen!
     */
    private Converter<Jwt, ? extends AbstractAuthenticationToken> jwtAuthenticationConverter() {

        JwtGrantedAuthoritiesConverter gac = new JwtGrantedAuthoritiesConverter();
        gac.setAuthoritiesClaimName("cognito:groups");
        gac.setAuthorityPrefix(""); // WICHTIG: Token enthält bereits ROLE_

        JwtAuthenticationConverter jac = new JwtAuthenticationConverter();
        jac.setJwtGrantedAuthoritiesConverter(gac);

        return jac;
    }
}