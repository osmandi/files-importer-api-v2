include ./.env

auth:
	# Get .tiny file for Tinybird authentication
	docker run -v ./:/app --env-file ./.env tinybirdco/tinybird-cli-docker /bin/bash -c 'cd /app && \
		tb auth --token "$$TB_TOKEN"'

datasource:
	# Create datasources in Tinybird
	docker run -v ./:/app tinybirdco/tinybird-cli-docker /bin/bash -c 'cd /app && \
		tb push ./datasources/departments.datasource && \
		tb push ./datasources/hired_employees.datasource && \
		tb push ./datasources/jobs.datasource'

load:
	# Usage of API to load CSV
	## Load departments
	curl \
		-H "Authorization: Bearer $(TB_TOKEN)" \
		-X POST 'https://api.us-east.aws.tinybird.co/v0/datasources?format=csv&name=departments&mode=append' \
		-F csv=@./raw/departments.csv
	## Load hired_employees
	curl \
		-H "Authorization: Bearer $(TB_TOKEN)" \
		-X POST 'https://api.us-east.aws.tinybird.co/v0/datasources?format=csv&name=hired_employees&mode=append' \
		-F csv=@./raw/hired_employees.csv
	## Load jobs
	curl \
		-H "Authorization: Bearer $(TB_TOKEN)" \
		-X POST 'https://api.us-east.aws.tinybird.co/v0/datasources?format=csv&name=jobs&mode=append' \
		-F csv=@./raw/jobs.csv

api:
	# Create endpoints
	docker run -v ./:/app tinybirdco/tinybird-cli-docker /bin/bash -c 'cd /app && \
		tb push ./endpoints/employees.pipe && \
		tb push ./endpoints/hired.pipe'

token:
	# Create a token with a scope
	docker run -v ./:/app tinybirdco/tinybird-cli-docker /bin/bash -c 'cd /app && \
		tb token create static my_read_token \
			--scope PIPES:READ --resource employees \
			--scope PIPES:READ --resource hired'

demo:
	# Execution to show a demo for the interview
	make auth && \
		make datasource && \
		make load && \
		make api && \
		make token

clean:
	# Delete data sources, pipes & endpoints tokens
	docker run -v ./:/app tinybirdco/tinybird-cli-docker /bin/bash -c 'cd /app && \
		tb datasource rm departments --yes ; \
		tb datasource rm hired_employees --yes ; \
		tb datasource rm jobs --yes ; \
		tb pipe rm employees --yes ; \
		tb pipe rm hired --yes; \
		tb token rm my_read_token --yes'
