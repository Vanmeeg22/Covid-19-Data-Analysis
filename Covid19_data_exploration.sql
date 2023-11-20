--	COVID-19 DATA EXPLORATION

-- Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

-- Tables in the database

Select *
From PortfolioProject..CovidDeaths
Order by 3,4;

Select *
From PortfolioProject..CovidVaccinations
Order by 3,4;

-- Exploring table CovidDeaths

Select location, date, population, total_cases, new_cases, total_deaths
From PortfolioProject..CovidDeaths
Order by 1,2;

-- Checking the data type of all the columns in the table

Select COLUMN_NAME, DATA_TYPE
From INFORMATION_SCHEMA.COLUMNS
Where TABLE_NAME = 'CovidDeaths';

-- Changing 'nvarchar' to 'float' in order to perform division

Alter table CovidDeaths
Alter Column total_deaths float;
Alter table CovidDeaths
Alter Column total_cases float;

-- Checking the data type of the specific columns

Select COLUMN_NAME, DATA_TYPE
From INFORMATION_SCHEMA.COLUMNS
Where TABLE_NAME = 'CovidDeaths' And COLUMN_NAME In ('total_deaths', 'total_cases');

-- Total Cases vs Total Deaths
-- Shows what percentage of the total cases resulted in death

Select location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as death_rate
From PortfolioProject..CovidDeaths
Order by 1,2;

-- Checking by location
-- Shows the likelihood of dying if a person in India is contracted by covid-19

Select location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as death_rate
From PortfolioProject..CovidDeaths
Where location like '%india%'
Order by 1,2;

-- Total Cases vs Population
-- Shows what percentage of the population is infected by Covid-19

Select location, date, population, total_cases, (total_cases / population)*100 as cases_percentage
From PortfolioProject..CovidDeaths
Where location like '%india%'
Order by 1,2;

-- Continents are present in both 'continent' and 'location' columns. When the continents are present in the 'location' column, the 'continent' column is null. Hence, applying NOT NULL.

-- Countries with highest percentage of cases reported

Select location, population, MAX(total_cases) as Total_cases_count, MAX((total_cases / population)*100) as cases_rate
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
Order by cases_rate desc;

-- Countries with highest Covid-19 cases count per population

Select location, population, MAX(total_cases) as Total_cases_count, MAX((total_cases / population)*100) as cases_rate
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
Order by Total_cases_count desc;

-- Countries with highest death counts per population

Select location, MAX(CAST(total_deaths as int)) as Total_deaths_count
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
Order by Total_deaths_count desc;

-- Continents with highest death counts per population

Select continent, MAX(CAST(total_deaths as int)) as Total_deaths_count
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order by Total_deaths_count desc;

-- Since the above query only displays the highest total_deaths count from a country instead of continents as a whole, it needs to be displayed by 'location' instead of 'continent' WHERE continent is null.

Select location, MAX(CAST(total_deaths as int)) as Total_deaths_count
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
Order by Total_deaths_count desc;

-- GLOBAL NUMBERS

Select date, total_cases, total_deaths
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2;

Select date, SUM(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1, 2;

Select date, SUM(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths, SUM(new_deaths) / SUM(new_cases) * 100 as Death_Percentage
From PortfolioProject..CovidDeaths
Where continent is not null AND new_cases <> 0
Group by date
Order by 1, 2;

-- Total cases, Total Deaths, Total Death Percentage, Globally

Select SUM(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths, SUM(new_deaths) / SUM(new_cases) * 100 as Death_Percentage
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2;

-- Joining both the tables

Select *
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac On dea.location = vac.location AND dea.date = vac.date
Order by 3, 4;

-- Checking the data type of all the columns in the table

Select COLUMN_NAME, DATA_TYPE
From INFORMATION_SCHEMA.COLUMNS
Where TABLE_NAME = 'CovidVaccinations';

-- Total population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac On dea.location = vac.location AND dea.date = vac.date
Where dea.continent is not null
Order by 2, 3;

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as Rolling_new_vaccinations
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac On dea.location = vac.location AND dea.date = vac.date
Where dea.continent is not null
Order by 2, 3;

-- Using Common Table Expression (CTE) to temporarilly store the result set of the query. Works like a temporary table

With Pop_vs_Vac (continent, location, date, population, new_vaccinations, Rolling_new_vaccinations) as
(
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as Rolling_new_vaccinations
	From PortfolioProject..CovidDeaths as dea
	Join PortfolioProject..CovidVaccinations as vac On dea.location = vac.location AND dea.date = vac.date
	Where dea.continent is not null
)
Select *, (Rolling_new_vaccinations / population)*100 as Rolling_new_vaccinations_percentage
From Pop_vs_Vac;

-- Using temporary table to calculate 'Rolling_new_vaccinations_percentage'

DROP Table if exists #Pop_vs_Vac_percent
Create Table #Pop_vs_Vac_percent
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	Rolling_new_vaccinations numeric
)
Insert into #Pop_vs_Vac_percent
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as Rolling_new_vaccinations
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac On dea.location = vac.location AND dea.date = vac.date
Select *, (Rolling_new_vaccinations / population)*100 as Rolling_new_vaccinations_percentage
From #Pop_vs_Vac_percent;

-- Creating View to store data for visualization

Create View Pop_vs_Vac_percent as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as Rolling_new_vaccinations
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac On dea.location = vac.location AND dea.date = vac.date
Where dea.continent is not null