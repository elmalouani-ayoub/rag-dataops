.PHONY: build test docs clean docker

build:      ## seed + run + test (pipeline complet)
	dbt build --profiles-dir .

test:       ## tests de qualite uniquement
	dbt test --profiles-dir .

docs:       ## genere et sert la doc + lineage
	dbt docs generate --profiles-dir . && dbt docs serve --profiles-dir .

docker:     ## execute le pipeline dans un conteneur
	docker build -t rag-dataops . && docker run --rm rag-dataops

clean:
	dbt clean --profiles-dir . || true
