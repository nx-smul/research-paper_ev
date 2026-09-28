# Sources for: EV Charging Station Optimization in Dhaka (MCLP, MATLAB)

VERIFICATION NOTE: This is a working bibliography, not a validated reference list.
Only the specific corrections and qualifications below have been checked against
publisher, Crossref, arXiv, or source pages. An entry without a [verify] label has
not necessarily been fully audited. Check every final citation against its primary
source before submission. A source listed here does not by itself validate any
model input or result.

======================================================================
A. MCLP AND LOCATION-SCIENCE FOUNDATIONS (cite in your Methodology)
======================================================================

1. Church, R., & ReVelle, C. (1974). The maximal covering location problem.
   Papers of the Regional Science Association, 32, 101-118.
   https://doi.org/10.1007/BF01942293
   -> The original MCLP paper. Cite for your core model.

2. Murray, A. T. (2016). Maximal Coverage Location Problem. International Regional
   Science Review, 39(1), 5-27.
   https://doi.org/10.1177/0160017615600222
   -> Overview of MCLP applications and extensions.

3. Church, R. L., & Roberts, K. L. (1983). Generalized coverage models and public
   facility location. Papers of the Regional Science Association, 53, 117-135.
   https://doi.org/10.1007/BF01939922
   -> Generalized coverage model. Confirm the paper's exact formulation matches the
      distance-decay function used in your model before citing it for that function.

4. Karasakal, O., & Karasakal, E. K. (2004). A maximal covering location model in
   the presence of partial coverage. Computers & Operations Research, 31, 1515-1526.
   https://doi.org/10.1016/S0305-0548(03)00105-9
   -> Supports partial coverage; do not treat this citation alone as validation of
      a particular distance-weighted coverage function.

5. Berman, O., Krass, D., & Drezner, Z. (2003). The gradual covering decay location
   problem on a network. European Journal of Operational Research, 151(3), 474-480.
   https://doi.org/10.1016/S0377-2217(02)00604-5
   -> Gradual decay of coverage with distance.

6. Balakrishnan, P. V., & Storbeck, J. E. (1991). McThresh: Modeling Maximum
   Coverage with Threshold Constraints. Environment and Planning B: Planning and
   Design, 18(4), 459-472.
   https://journals.sagepub.com/doi/10.1068/b180459
   -> This is not the cited 1988 "Capacitated covering models" paper. It presents
      threshold-demand constraints; cite it only if those constraints match your
      formulation, not as generic proof of station capacity constraints.

7. Suarez, L., Porras, C., & Rosete, A. (2022). Experimental study with several demand
   allocation approaches in the capacitated maximal covering location problem.
   Revista Cubana de Ciencias Informaticas, 16(1), 128-143.
   https://rcci.uci.cu/index.php/RCCI/article/download/2415/776/776

======================================================================
B. EV CHARGING STATION SITING STUDIES (Literature Review)
======================================================================

8. Designing an Optimized Electric Vehicle Charging Station Infrastructure for Urban
   Area: A Case study from Indonesia. arXiv:2209.03448 (2022). [verify authors]
   https://arxiv.org/abs/2209.03448
   -> The abstract confirms a maximal covering location model, Surabaya, electric
      motorcycles and cars, and sensitivity analysis. It is an arXiv preprint, not
      evidence that the Dhaka model's inputs or estimates are valid.

9. Systematic literature review on location analysis for EV charging infrastructure
   planning (claimed 91 peer-reviewed studies, 2011-2024). IIETA.
   [verify authors, exact title, study count, and publication metadata in the PDF]
   https://www.iieta.org/download/file/fid/174928
   -> Use only after checking the review's inclusion criteria and the exact gap
      statements; a review's scope does not establish a Dhaka-specific gap.

10. Optimal location for electric vehicle charging station using multiobjective
    assessment method (COPRAS-based MCDM). Sustainable Energy Research, 12, Article 36
    (2025). [verify exact title, authors, and article metadata against publisher]
    https://sustainenergyres.springeropen.com/articles/10.1186/s40807-025-00184-w

11. Zhao, H., Gao, J., & Cheng, X. (2023). Electric vehicle solar charging station
    siting study based on GIS and multi-criteria decision-making: A case study of
    China. Sustainability, 15(14), 10967.
    https://ideas.repec.org/a/gam/jsusta/v15y2023i14p10967-d1192940.html

12. Zeng, X. (2025). Spatial optimization for electric vehicle charging station
    locations using a GIS-based approach: A case study from Minnesota, USA.
    ICA-Advances, 5, 36.
    https://ica-adv.copernicus.org/articles/5/36/2025/ica-adv-5-36-2025.pdf

13. Faridah, L., Asnawi, R., Jati, H., & Kusuma, N. (2026). Optimization techniques
    for siting solar-powered EV charging stations: A systematic review and
    methodological classification. Int. J. of Power Electronics and Drive Systems
    (IJPEDS), 17(2), 1355-1368.
    https://ijpeds.iaescore.com/index.php/IJPEDS/article/view/24318

14. Feng, J., Xu, S. X., & Li, M. (2021). A novel multi-criteria decision-making
    method for selecting the site of an electric-vehicle charging station from a
    sustainable perspective. Sustainable Cities and Society, 65, 102623.
    https://doi.org/10.1016/j.scs.2020.102623
    (Found via a reference list. Read the abstract before citing.)

15. Erbaş, M., Kabak, M., Özceylan, E., & Çetinkaya, C. (2018). Optimal siting of
    electric vehicle charging stations: A GIS-based fuzzy Multi-Criteria Decision
    Analysis. Energy, 163, 1017-1031.
    https://doi.org/10.1016/j.energy.2018.08.140

16. Aljuboori, A. W. (2021). A procedure for optimizing the location of electric
    vehicle charging stations. MSc thesis, Civil Engineering.
    http://hdl.handle.net/11073/21605

======================================================================
C. BANGLADESH / DHAKA EV CONTEXT AND POLICY
======================================================================

17. Power Division, Ministry of Power, Energy and Mineral Resources (2022).
    Electric Vehicle Charging Guideline. Government of Bangladesh.
    https://www.mpemr.gov.bd/assets/uploads/various/1711872073_Electric Vehicle Charging-english.pdf
    -> Official charging-station guideline. Cite for policy context and
       charger-type assumptions.

18. Khalequzzaman, M., & Islam, S. (2026). Overview of electric vehicle charging
    infrastructure in Bangladesh. Power Division presentation, SAARC Energy training
    workshop. https://www.saarcenergy.org/wp-content/uploads/2026/08/Bangladesh.pdf
    -> The PDF is image-based; verify author names, presentation title, date, and
       claims directly from the slides before citing. Prefer the underlying policy
       documents for policy claims.

19. Dhaka Tribune. CG Runner, Genex Infrastructure collaborate for extensive EV
    charging network across the country.
    https://www.dhakatribune.com/amp/business/337369/cg-runner-genex-infrastructure-collaborate-for
    -> Reports company plans and a contemporaneous estimate of operational
       charging stations. Its 30% target statement is secondary reporting; cite the
       2023 government policy itself for the target.

20. World Bank. Electric Mobility Roadmap for Bangladesh (procurement notice).
    https://www.worldbank.org/en/about/corporate-procurement/business-opportunities/administrative-procurement/rfxnow-2005422-electric-mobility-roadmap-for-bangladesh
    -> Procurement notice, not the primary source for the 30% target. Use the
       government policy document for that claim.

21. Ahmed, A., Rahman, M., Chowdhury, M. J., & Al Mamun, K. A. (2025). Design and
    analysis of a grid-connected DC fast charging station for Dhaka-Chittagong
    highway. arXiv:2505.21648. https://arxiv.org/abs/2505.21648
    -> Bangladesh-specific charging station design (technical, not siting).

22. Hossain, K. M. M., Hossain, M., Appy, T. A., Nawar, N., & Huda, A. S. N.
    Comparative analysis of renewable energy based EV charging stations for
    different locations in Bangladesh. IEEE conference paper.
    [verify title, authors, year, conference, and peer-review status]
    https://vufind.lboro.ac.uk/PrimoRecord/cdi_ieee_primary_10428790

23. Optimization of Electric Vehicle (EV) Charging Station Design for Urban Mobility
    (hybrid solar/hydrogen station, Bangladesh). STI 2025 conference, EasyChair.
    [slide listing; verify whether a citable peer-reviewed paper/proceedings exists]
    https://easychair.org/smart-slide/slide/d4Vz

======================================================================
D. DATA SOURCES BEHIND MODEL INPUTS
======================================================================

The repository README describes the expanded Dhaka candidate weights and land
costs as 1-10 planning estimates, not measured traffic, registration, census, or
property-price observations. The sources in this section provide context, but do
not validate candidate-level values. Treat results as scenario analysis unless
those inputs are replaced or calibrated with traceable, site-level data.

--- Vehicle mix (Weight_Car vs Weight_Bike) ---

24. Bonik Barta. Only 396 electric vehicles registered in the country (BRTA data:
    243 motorcycles, 94 hardtop jeeps, 54 private cars, 3 microbuses).
    https://en.bonikbarta.com/bangladesh/tboqYkZ0YC2NoDxl
    -> The article also lists one delivery van and one auto-rickshaw; the four
       categories above sum to 394, not 396. This is secondary reporting of BRTA
       data, and the national registered-vehicle counts are not Dhaka site-level
       demand estimates.

25. Lightcastle Partners. Current status of EV adoption in Bangladesh (25,000-30,000
    EVs on roads vs ~400 registered; ~5.5 million informal three-wheelers).
    https://lightcastlepartners.com/?p=36200
    -> This URL now redirects to a December 2025 article. Locate the original source
       and its date/method before reusing the older counts; the registered-vehicle
       and informal three-wheeler categories are not directly comparable.

26. The Business Standard. Tougher policy soon to regulate battery-run rickshaws in
    Bangladesh (BRTA estimate: 1-1.2 million in Dhaka).
    https://www.tbsnews.net/bangladesh/tougher-policy-soon-regulate-battery-run-rickshaws-bangladesh-1207206
    -> The article reports an estimate of 10-12 lakh unregistered battery-run
       rickshaws in Dhaka, distinct from BRTA-registered electric motor vehicles.
       Do not use it as an electric-motorcycle demand count without an explicit,
       defensible category mapping.

--- Population density (PopDensity) ---

27. Bangladesh Bureau of Statistics (2022). Population and Housing Census 2022.
    https://ghdx.healthdata.org/node/533463 (catalogue entry)
    -> GHDx is a catalogue, not the census publisher. Cite the relevant BBS census
       table/volume directly for population or density values.

28. Prothom Alo (2022). Over 10.2m people live in Dhaka city: BBS (DNCC 5,979,537;
    DSCC 4,299,345).
    https://en.prothomalo.com/bangladesh/city/fzkq4hv4k7

29. The Financial Express (2022). Population now at 165.16m (DSCC 39,353 per sq km;
    DNCC 30,474 per sq km).
    https://today.thefinancialexpress.com.bd/print/population-now-at-16516m-1658944848

30. City Population (BBS 2022 data). Dhaka South City Corporation: thana and ward
    populations (e.g., Sher-e-Bangla Nagar 17,033).
    https://www.citypopulation.de/en/bangladesh/dhaka/
    (The Dhaka North page on the same site has Mirpur, Gulshan, etc.)
    -> The supplied URL currently resolves to a Dhaka South page, while the example
       is Sher-e-Bangla Nagar. Verify the administrative unit and table source
       before citing that number; use the matching DNCC/DSCC census table.

--- Land cost (LandCost) ---

The property and apartment articles below are secondary sources and generally
report asking prices or apartment prices, not verified site-acquisition costs.
They cannot substantiate numeric, candidate-specific LandCost values without
additional land transaction/lease data and a stated conversion method.

31. The Daily Star, Property Guru (2024). Breathing room or bottleneck? (Gulshan Tk
    18,000-36,000/sq ft; Banani; Baridhara Tk 22,000-30,000; Dhanmondi Tk
    15,000-25,000).
    https://online.thedailystar.net/node/3994906

32. Starpath Holdings (2025). Dhaka residential property trends (Gulshan/Banani land
    BDT 160,000-220,000/katha; peripheral BDT 55,000-90,000/katha).
    https://starpathholdings.com/dhaka-residential-property-trends-market-insights-and-future-outlook/

33. Dhaka Tribune (Time capsule: Dhaka real estate). Motijheel land around Tk 5 crore
    per katha; Uttara, Mirpur and Bashundhara are the affordable areas.
    https://www.dhakatribune.com/business/191006/time-capsule-dhaka-real-estate
    (CORRECTION: an earlier message showed a tbsnews.net link for this article.
     The correct publisher is Dhaka Tribune, with the link above.)

34. Assure Group (2025). Average flat price in Dhaka (Uttara Tk 5,000-10,000/sq ft).
    https://www.assuregroupbd.com/media/blog/average-flat-prices-in-dhaka

35. The Business Standard (2023). Mirpur, Uttara most sought-after areas for
    residence in 2023 (Bproperty analysis).
    https://www.tbsnews.net/node/768098
    -> This reports portal users' flat search preferences, not population, EV
       demand, or land acquisition costs.

36. The Business Standard. Apartment price rides on scarce land (Gulshan, Banani,
    Dhanmondi, Mohammadpur price trends).
    https://www.tbsnews.net/companies/real-estate/apartment-price-rides-scarce-land-208966

--- Transit demand (metro stations) ---

The ridership articles below report system-wide daily averages or single-day
records. They are context only; they do not provide passenger origins, station-
level demand, or EV charging demand.

37. The Financial Express. MRT-6 sees record number of passengers (about 350,000
    daily average).
    https://thefinancialexpress.com.bd/home/mrt-6-sees-record-number-of-passengers

38. The Financial Express. Metro rail sets new ridership record (403,164 in one day).
    https://thefinancialexpress.com.bd/home/metro-rail-sets-new-ridership-record

39. Roy, P., et al. (2025). Impact of MRT Line 6 (Dhaka Metro Rail) on commuter modal
    shift, travel time reduction, and future expansion prospects. 1st International
    Conference on Science and Humanities for Sustainable Development, DUET, Gazipur.
    https://www.aiub.edu/Files/student-research/IMPACT_OF_MRT_LINE_6_DHAKA_METRO_RAIL_ON_COMMUTER_MODAL_SHIFT_TRAVEL_TIME_REDUCTION_AND_FUTURE_EXPANSION_PROSPECTS.html

40. MRT Line 6 (Wikipedia). Background only; cite the news sources above instead.
    https://en.wikipedia.org/wiki/MRT_Line_6