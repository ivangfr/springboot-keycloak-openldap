package com.ivanfranchin.simpleservice.security;

import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;
import org.springframework.stereotype.Component;

@Component
public class JwtAuthenticationTokenConverter
    implements Converter<Jwt, AbstractAuthenticationToken> {

  private static final JwtGrantedAuthoritiesConverter jwtGrantedAuthoritiesConverter =
      new JwtGrantedAuthoritiesConverter();

  @Value("${jwt.auth.converter.resource-id}")
  private String resourceId;

  @Value("${jwt.auth.converter.principal-attribute}")
  private String principalAttribute;

  @Override
  public AbstractAuthenticationToken convert(Jwt jwt) {
    Collection<GrantedAuthority> authorities =
        Stream.concat(
                jwtGrantedAuthoritiesConverter.convert(jwt).stream(),
                extractResourceRoles(jwt).stream())
            .collect(Collectors.toSet());
    String claimName = principalAttribute == null ? JwtClaimNames.SUB : principalAttribute;
    return new JwtAuthenticationToken(jwt, authorities, jwt.getClaim(claimName));
  }

  private Collection<? extends GrantedAuthority> extractResourceRoles(Jwt jwt) {
    return Optional.ofNullable(jwt.getClaim("resource_access"))
        .map(resourceAccess -> (Map<String, Object>) resourceAccess)
        .map(resourceAccess -> (Map<String, Object>) resourceAccess.get(resourceId))
        .map(resource -> (Collection<String>) resource.get("roles"))
        .orElse(Collections.emptySet())
        .stream()
        .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
        .collect(Collectors.toSet());
  }
}
