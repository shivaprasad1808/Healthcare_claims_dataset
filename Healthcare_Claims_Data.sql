create database project;

use project;

CREATE TABLE claimsdata (
    ClaimID            VARCHAR(20),
    ProviderID         BIGINT     ,
    PatientID          BIGINT     ,
    DateOfService      DATE       ,
    BilledAmount       INT        ,
    ProcedureCode      INT        ,
    DiagnosisCode      VARCHAR(20),
    AllowedAmount      INT        ,
    PaidAmount         INT        ,
    InsuranceType      VARCHAR(50),
    ClaimStatus        VARCHAR(50),
    ReasonCode         VARCHAR(100),
    FollowUpRequired   VARCHAR(10),
    ARStatus           VARCHAR(50),
    Outcome            VARCHAR(50),

);


BULK INSERT ClaimsData
FROM 'C:\Users\DELL\Desktop\DATA\claims_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

select * from claimsdata; 


--1. Retrieve all claims where the claim status is "Denied".

select * from claimsdata where ClaimStatus = 'Denied';

--2. Find the total billed amount per insurance type with total_billed_amount descending.

select InsuranceType, sum(BilledAmount) as total_billed_amount 
from claimsdata
group by InsuranceType
order by total_billed_amount desc;

--3. Get a list of distinct diagnosis codes used in the dataset.

select distinct DiagnosisCode from claimsdata;

--4. Show all claims where Paid Amount is less than Allowed Amount.

select * from claimsdata
where PaidAmount < AllowedAmount;

--5. Count how many claims required follow-up.

select count(FollowUpRequired) as Follow_up_required
from claimsdata
where FollowUpRequired = 'Yes';

--OR--

select count(case when FollowUpRequired = 'Yes' then 1 end) as Follow_up_required
from claimsdata;

--6. Find the average Paid Amount per Insurance Type, output based on avg_amount_paid descending order.

select InsuranceType, Avg(PaidAmount) as avg_amount_paid
from claimsdata
group by InsuranceType
order by avg_amount_paid desc; 

--7. Get the top 5 providerID's with the highest total billed amount in descending order.

select top 5 providerID,  BilledAmount as amount_billed
from claimsdata 
order by amount_billed DESC;

--8. Find the claimID/IDs with the maximum billed amount and their claim status.

with CTE as (
select  claimID, rank() over(order by BilledAmount DESC) as max_amount_billed from claimsdata
)
select claimID from CTE where max_amount_billed =1;

--9. Calculate claim denial rate (percentage of claims with status = 'Denied').

select * from claimsdata;

select count(ClaimStatus)*100 / (select count(ClaimStatus) as ClaimStatus from claimsdata)
as claim_denied_percent
from claimsdata
where ClaimStatus = 'Denied';

--OR--
with CTE as (
select 
count(case when ClaimStatus = 'Denied' then 1 end) as claim_denied
from claimsdata)
select claim_denied*100/(select count(ClaimStatus) as ClaimStatus from claimsdata) 
as claim_denied_percent
from CTE

--10. Find the month-wise trend of total billed vs. paid amounts.

select FORMAT(DateOfServiCe, 'yyyy-MM') as month,
SUM(BilledAmount) as Total_billed_amount,
sum(PaidAmount) as Total_paid_amount
from claimsdata
group by FORMAT(DateOfServiCe, 'yyyy-MM')
ORDER BY Month;

--11. Calculate the average payment efficiency (Paid Amount / Billed Amount) by insurance type.

select InsuranceType, sum(PaidAmount)*100/NULLIF(sum(BilledAmount),0)   as average_payment_efficiency
from claimsdata
group by InsuranceType 

--12. For each diagnosis code, find the most common reason code for denial.

with CTE as (
select DiagnosisCode, ReasonCode, 
COUNT(ClaimStatus) AS DenialCount ,
ROW_NUMBER() OVER (PARTITION BY DiagnosisCode ORDER BY COUNT(ClaimStatus) DESC) AS rn
from claimsdata
WHERE ClaimStatus = 'Denied'
group by DiagnosisCode, ReasonCode)
select DiagnosisCode, ReasonCode, DenialCount
from CTE where rn=1;

