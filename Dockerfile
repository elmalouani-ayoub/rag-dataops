# Conteneurise le pipeline pour une execution reproductible "n'importe ou".
FROM python:3.11-slim
WORKDIR /pipeline
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
# Par defaut : reconstruit tout (seed + run + test) sur DuckDB.
CMD ["dbt", "build", "--profiles-dir", "."]
