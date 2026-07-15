package com.trianglobe;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.info.BuildProperties;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * Application-level health check for the walking skeleton: proves the /api
 * route works through the whole stack. Infrastructure probes will use
 * Spring's own /actuator/health instead.
 */
@RestController
class HealthController {

	private final String version;

	HealthController(ObjectProvider<BuildProperties> buildProperties) {
		// BuildProperties exists only in a packaged build (the build-info goal
		// in pom.xml creates it); when running from the IDE it is absent.
		BuildProperties props = buildProperties.getIfAvailable();
		this.version = props != null ? props.getVersion() : "dev";
	}

	@GetMapping("/api/health")
	HealthResponse health()  {
		return new HealthResponse("ok", this.version);
	}
}

record HealthResponse(String status, String version) {}