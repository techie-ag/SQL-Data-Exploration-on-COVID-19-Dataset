SELECT *
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProjects.dbo.CovidVaccinations
--ORDER BY 3,4

--The next query is to get the data for my use

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects.dbo.CovidDeaths
ORDER BY 1,2

--Calculate the percentage of death encountered (Looking at total cases vs total deaths)

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS 'DeathPercent'
FROM PortfolioProjects.dbo.CovidDeaths
ORDER BY 1,2

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS 'DeathPercent'
FROM PortfolioProjects.dbo.CovidDeaths
WHERE Location like '%Nigeria%'
ORDER BY 1,2

--Calculate the percentage of population with covid

SELECT Location, date,population, total_cases, (total_cases/population)*100 AS 'PopulationPercent'
FROM PortfolioProjects.dbo.CovidDeaths
WHERE Location like '%Nigeria%'
ORDER BY 1,2

--Calculate for countries with highest infection rate

SELECT Location,population, MAX(total_cases) AS Highestinfectioncount, MAX(total_cases/population)*100 AS 'PopulationPercentInfected'
FROM PortfolioProjects.dbo.CovidDeaths
--WHERE Location like '%Nigeria%'
GROUP BY Location, population
ORDER BY PopulationPercentInfected DESC

--Calculate for countries with highest death count per population

SELECT Location, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProjects.dbo.CovidDeaths
--WHERE Location like '%Nigeria%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

SELECT Location, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProjects.dbo.CovidDeaths
--WHERE Location like '%Nigeria%'
WHERE continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC


---WORK ON THE DATA BY CONTINENT
--Calculate the continents with highest death count per population


SELECT continent, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProjects.dbo.CovidDeaths
--WHERE Location like '%Nigeria%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global numbers of Death per population across the World
SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS 'DeathPercent'
FROM PortfolioProjects.dbo.CovidDeaths
--WHERE Location like '%Nigeria%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 AS 'DeathPercent'
FROM PortfolioProjects.dbo.CovidDeaths
--WHERE Location like '%Nigeria%'
WHERE continent is not null
ORDER BY 1,2

--In this section, I joined the two tables in order to query them
--To refresh the memory on what is contained in the second table ie vaccination table

SELECT *
FROM PortfolioProjects.dbo.CovidVaccinations
ORDER BY 3,4

--Join the tables by location and date

SELECT *
FROM PortfolioProjects.dbo.CovidDeaths as death
JOIN PortfolioProjects.dbo.CovidVaccinations as vaccine
     ON death.location = vaccine.location
	 AND death.date = vaccine.date

--Calculate the number of vaccination from total population

SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations
FROM PortfolioProjects.dbo.CovidDeaths as death
JOIN PortfolioProjects.dbo.CovidVaccinations as vaccine
     ON death.location = vaccine.location
	 AND death.date = vaccine.date
WHERE death.continent is not null
ORDER BY 1,2,3

--Using Partition By
--Convert(int, 'column_name') works the same way as the CAST used in the previous queries

SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations,
SUM(CONVERT(int,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date)
FROM PortfolioProjects.dbo.CovidDeaths as death
JOIN PortfolioProjects.dbo.CovidVaccinations as vaccine
     ON death.location = vaccine.location
	 AND death.date = vaccine.date
WHERE death.continent is not null
ORDER BY 2,3

--USE CTE
--Create a CTE to act as a temporary table to use for some of the queries
---Calculate the number of people vaccinated each day

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations,
SUM(CONVERT(int,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProjects.dbo.CovidDeaths as death
JOIN PortfolioProjects.dbo.CovidVaccinations as vaccine
     ON death.location = vaccine.location
	 AND death.date = vaccine.date
WHERE death.continent is not null
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

--TEMP TABLE
--DROP TABLE IF EXISTS ##PercentOfPopulationVaccinated
--Remember to use the above query whenever an alteration is carried out on a created table

CREATE TABLE #PercentOfPopulationVaccinated
(
Continent nvarchar(150),
Location nvarchar(150),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentOfPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations,
SUM(CONVERT(int,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date)
FROM PortfolioProjects.dbo.CovidDeaths as death
JOIN PortfolioProjects.dbo.CovidVaccinations as vaccine
     ON death.location = vaccine.location
	 AND death.date = vaccine.date
WHERE death.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentOfPopulationVaccinated

--Creating a view to store my data for visualization purposes

CREATE VIEW PercentOfPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations,
SUM(CONVERT(int,vaccine.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM PortfolioProjects.dbo.CovidDeaths as death
JOIN PortfolioProjects.dbo.CovidVaccinations as vaccine
     ON death.location = vaccine.location
	 AND death.date = vaccine.date
WHERE death.continent is not null