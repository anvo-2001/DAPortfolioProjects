/*
COVID 19 Data Exploration. Data source: https://ourworldindata.org/covid-deaths 
Skills used: Join, CTE, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--Creating temp table #CD to start analyzing
drop table if exists #CD
select * into #CD
from CovidDeaths
where continent is not null and date != '2023-02-01'
order by 1,2

-- Showing list of countries that will be imported into Dim.Country table for visualizations

select distinct iso_code, location
from #CD

-- Total infections and Total deaths up to 31 Jan 2023 
-- Shows coutries with the highest COVID cases and deaths

select location 
	, ISNULL(MAX(total_cases),0) as total_cases
	, ISNULL(MAX(total_deaths),0) as total_deaths
from #CD
--where location = 'Vietnam'
group by location
order by 2 desc

-- Total deaths vs Total cases ; Total Cases vs Country Population
-- Show fatality ratio and infection rate among population in each coutnry

select location
	, MAX(population) as population
	, ISNULL(MAX(total_deaths),0) as total_deaths
	, ISNULL(MAX(total_cases),0) as total_cases
	, ISNULL(CAST((MAX(total_cases)*1.0/MAX(population)*100)as decimal(10,2)),0) as percent_population_infected
	, ISNULL(CAST((MAX(total_deaths)*1.0/MAX(total_cases)* 100) as decimal(10,2)),0) case_fatality_ratio
from #CD
--where location = 'Vietnam'
group by location
order by 5 desc

-- Look at Daily updates about New cases, New deaths, Total figures, Fatality Ratio and Percent population infected 
select continent, location, date, population
	, ISNULL(new_cases,0) as new_cases
	, ISNULL(new_deaths,0) as new_deaths
	, ISNULL(total_cases,0) as total_cases
	, ISNULL(total_deaths,0) as total_deaths
	, CAST(ISNULL(total_cases*1.0/population*100,0) as decimal(10,2)) as percent_population_infected
	, CAST(ISNULL(total_deaths*1.0/total_cases*100,0) as decimal(10,2)) as fatality_ratio
from #CD
--where location = 'Vietnam'
order by 1,2


-- LET'S BREAK THINGS DON BY CONTINENT
-- Showing the continent with the highest Death Cases

select location as continent
	, MAX(total_deaths) as death_cases
	, MAX(total_cases) as total_cases
	, CAST(ISNULL((MAX(total_deaths)*1.0/MAX(total_cases))*100,0) as decimal(10,2)) as fatality_ratio
from CovidDeaths
where continent is null AND location not like '%income'
group by location
order by total_cases desc


-- GLOBAL NUMBERS 
-- Show worldwide daily COVID cases update 

select date
	, ISNULL(SUM(new_deaths),0) as total_deaths
	, ISNULL(SUM(new_cases),0) as total_cases
	, CAST(ISNULL((SUM(new_deaths)*1.0/SUM(new_cases)*100),0) as decimal(10,2)) as death_pct
from #CD
--where location = 'Vietnam'
group by date
order by date desc

-- GET VACCINATIONS INFO WITH JOINS

select *
from CovidDeaths da
join CovidVaccinations va
	on da.location = va.location
	and da.date = va.date

-- Show the Rolling number of COVID vaccinations by location by date

select da.location, da.date
	, ISNULL(va.new_vaccinations,0) as new_vaccinations
	, ISNULL(SUM(CAST(va.new_vaccinations as bigint)) over(partition by da.location order by da.location, da.date),0) as rolling_vaccinations
from CovidDeaths da
join CovidVaccinations va
	on da.location = va.location
	and da.date = va.date
where da.continent is not null
order by location, date desc

-- CTE to calculate rolling_vaccinations_among_population
with vacin as
(select da.location, da.date, da.population
	, ISNULL(va.new_vaccinations,0) as new_vaccinations
	, ISNULL(SUM(CAST(va.new_vaccinations as bigint)) over(partition by da.location order by da.location, da.date),0) as rolling_vaccinations
from CovidDeaths da
join CovidVaccinations va
	on da.location = va.location
	and da.date = va.date
where da.continent is not null
)
select *
	, CAST((rolling_vaccinations*1.0/population*100) as decimal(10,2)) as rolling_vaccinations_among_population
from vacin
order by location, date desc

-- Creating View for Vizualization

Create View VaccinationsAmongPopulation as

select da.location
	, MAX(population) as population
	, ISNULL(SUM(CAST(va.new_vaccinations as bigint)),0)  as total_vaccinations
	, CAST((ISNULL(SUM(CAST(va.new_vaccinations as bigint)),0)*1.0/ MAX(population)) as decimal(10,2))total_vaccninations_among_population
from CovidDeaths da
join CovidVaccinations va
	on da.location = va.location
	and da.date = va.date
where da.continent is not null
group by da.location
order by 4 desc

