-- # Executive Overview Metrics

create view clean.executive_overview as
select
    count(distinct a.account_id) as total_customers,
	sum(s.mrr_amount) as total_mrr,
	sum(s.arr_amount) as total_arr,
	round(100.0 * sum(case when a.churn_flag then 1 else 0 end) /
	count(*), 2) as churn_rate,
	avg(a.seats) as avg_seats
from clean.accounts a
join clean.subscriptions s
on a.account_id = s.account_id;

select * from clean.executive_overview;


-- # Monthly MRR Trend

create view clean.mrr_trend as
select
    date_trunc('month', start_date::timestamp) as month,
	sum(mrr_amount) as total_mrr
from clean.subscriptions
group by 1
order by 1;

select * from clean.mrr_trend;


-- # Customers by Referral & Industry

create view clean.customer_segments as
select
    a.referral_source,
	a.industry,
	count(distinct a.account_id) as customers
from clean.accounts a
group by 1,2;

select * from clean.customer_segments;


-- # Churn by Industry & Plan

create view clean.churn_analysis as
select
    a.industry,
	s.plan_tier,
	count(distinct a.account_id)
	filter(where a.churn_flag) as churned_customers,
	count(distinct a.account_id) as total_customers,
	round(100.0 * count(distinct a.account_id) filter (where a.churn_flag) /
	count(distinct a.account_id), 2) as churn_rate
from clean.accounts a
join clean.subscriptions s on a.account_id = s.account_id
group by 1,2;

select * from clean.churn_analysis;


-- # Feature Usage & Support Metrics

create view clean.product_support as
with feature_summary as (
select
    f.feature_name,
	sum(f.usage_count) as total_usage,
	avg(f.error_count) as avg_errors,
	s.account_id
from clean.feature_usage f
    join clean.subscriptions s on f.subscription_id = s.subscription_id
	group by f.feature_name, s.account_id),
	ticket_summary as (
select
    a.account_id,
	avg(t.resolution_time_hours) as avg_resolution_time,
	avg(t.satisfaction_score) as avg_satisfaction
	from clean.accounts a
	left join clean.support_tickets t on a.account_id = t.account_id
	group by a.account_id)
select
	fs.feature_name,
	sum(fs.total_usage) as total_usage,
	avg(fs.avg_errors) as avg_errors,
	avg(ts.avg_resolution_time) as avg_resolution_time,
	avg(ts.avg_satisfaction) as avg_satisfaction
from feature_summary fs
	left join ticket_summary ts on fs.account_id = ts.account_id
	group by fs.feature_name;

select * from clean.product_support;