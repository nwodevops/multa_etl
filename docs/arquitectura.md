```mermaid
flowchart TD
    HOP["Apache Hop<br/>(wf_main.hwf)"]

    subgraph H2["Staging H2 in-memory"]
        RESET["Reset H2 clean<br/>(stop + start + DDL)"]
        DBH2[("mem:csep")]
    end

    subgraph R["Capa R (lógica aislada)"]
        LOG["r/logica/<br/>(único .R)"]
    end

    subgraph FUENTES["Fuentes"]
        ORASISUD[("Oracle SISUD")]
        MYSQL[("MySQL gapps")]
        SHEETS[("Google Sheets<br/>(client_secret.json)")]
    end

    ORAREPO[("Oracle REPOCSEP<br/>destino")]
    PBI["Power BI"]

    HOP --> RESET
    RESET --> DBH2
    HOP --> LOG
    LOG --> DBH2
    LOG -->|"TRUNCATE + INSERT"| ORAREPO
    ORAREPO -->|"input"| PBI
    HOP -.->|"extract (opcional)"| FUENTES
    CONFIG["project-config.json<br/>(variables)"] -.-> HOP
```
