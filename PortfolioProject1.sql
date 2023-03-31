select * from CovidDeaths$

select * from CovidVaccinations$

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths$
where location like '%states%'
order by 1,2

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths$
where location='india'
order by 1,2

--- shows what percentage what % of population got covid
select location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
from CovidDeaths$
where location like '%states%'
order by 1,2

select location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
from CovidDeaths$
where location='india'
order by 1,2

-- countries with highest infection rate 
select location, population, max(total_cases) as highestInfectionCount, max((total_cases/population))*100 as PercentagePopulationInfected
from CovidDeaths$
group by location, population
order by highestInfectionCount desc

select location, population, max(total_cases) as highestInfectionCount, max((total_cases/population))*100 as PercentagePopulationInfected
from CovidDeaths$
where location like '%states'
group by location, population
order by 1,2

--- countries with highest death count per population

select location, max(cast(total_Deaths as int)) as totalDeathCount
from CovidDeaths$
where continent is not null
group by location
order by totalDeathCount desc

-- break things by continent
select continent, max(cast(total_Deaths as int)) as totalDeathCount
from CovidDeaths$
where continent is not null
group by continent
order by totalDeathCount desc

select location, max(cast(total_Deaths as int)) as totalDeathCount
from CovidDeaths$
where continent is null
group by location
order by totalDeathCount desc

-- global death numbers
select date, sum(new_cases) as totalcases, sum(cast(new_deaths as int)) as totaldeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage 
from CovidDeaths$
where continent is not null
group by date
order by 1,2

select sum(new_cases) as totalcases, sum(cast(new_deaths as int)) as totaldeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage 
from CovidDeaths$
where continent is not null
order by 1,2

----- vaccination table

select * 
from CovidDeaths$ a 
join CovidVaccinations$ b 
on a.location=b.location 
and a.date=b.date

-- population vs vaccination
select a.continent, a.location, a.date, a.population, b.new_vaccinations
from CovidDeaths$ a 
join CovidVaccinations$ b 
on a.location=b.location 
and a.date=b.date
where a.continent is not null
order by 2,3

--- 
select a.continent, a.location, a.population, sum(cast(b.new_vaccinations as int )) as sumVaccinations
from CovidDeaths$ a 
join CovidVaccinations$ b 
on a.location=b.location 
and a.date=b.date
where a.continent is not null
group by a.continent, a.location, a.population
order by 2,3

----- RollingPeopleVaccinated

select a.continent, a.location, a.date, a.population, b.new_vaccinations,
sum(cast(b.new_vaccinations as int )) OVER (PARTITION BY a.location order by a.location, a.date) as RollingPeopleVaccinated
from CovidDeaths$ a 
join CovidVaccinations$ b 
on a.location=b.location 
and a.date=b.date
where a.continent is not null
order by 2,3


--- Use CTE (we cannot use the column which we created in the query again so we use cte or temp)
--- number of columns of cte must be as select query

with PopvsVac (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated) 
as
(
select a.continent, a.location, a.date, a.population, b.new_vaccinations,
sum(cast(b.new_vaccinations as int )) OVER (PARTITION BY a.location order by a.location, a.date) as RollingPeopleVaccinated
from CovidDeaths$ a 
join CovidVaccinations$ b 
on a.location=b.location 
and a.date=b.date
where a.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac

--- Temp table
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated 
select a.continent, a.location, a.date, a.population, b.new_vaccinations,
sum(cast(b.new_vaccinations as int )) OVER (PARTITION BY a.location order by a.location, a.date) as RollingPeopleVaccinated
from CovidDeaths$ a 
join CovidVaccinations$ b 
on a.location=b.location 
and a.date=b.date

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


--- creating view to store data for later visualization

create view PercentPopulationVaccinated as
select a.continent, a.location, a.date, a.population, b.new_vaccinations,
sum(cast(b.new_vaccinations as int )) OVER (PARTITION BY a.location order by a.location, a.date) as RollingPeopleVaccinated
from CovidDeaths$ a 
join CovidVaccinations$ b 
on a.location=b.location 
and a.date=b.date
where a.continent is not null

select * from PercentPopulationVaccinated