# transit

Estimate transit time-to-care for people receiving HIV care at the Bartlett Practice in Baltimore, Maryland, USA.

Data:

- GTFS feeds from local public transportation authorities [Public]
- Street network from OpenStreetMap [Public]
- Geocoded residential addresses, demographics, and visit outcomes for participants in the Johns Hopkins HIV Clinical Cohort [Private]

Code:

- libraries.R: Install required packages.
- transit_network.R: Build transit network and estimate transit time-to-clinic.
- transit_analysis.qmd: Estimate association between transit time-to-clinic and missed visits.
