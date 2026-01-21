CREATE OR REPLACE VIEW `vendor-ops-analysis.vendor_analysis.vendor_performance_summary` AS
with vendor_payment AS (SELECT vendor_name, month, sum(titles_processed) AS total_titles_processed,sum(titles_processed*rate_per_title) AS total_cost
FROM `vendor-ops-analysis.vendor_analysis.vendor_payment_report_2025`
GROUP BY vendor_name, month)

,overall_vendor_analysis AS (SELECT vp.month,
vp.vendor_name, 
vp.total_titles_processed, 
vp.total_cost, 
vq.titles_audited, 
vq.critical_defects,
vq.non_critical_defects,(vq.critical_defects + vq.non_critical_defects) AS total_defects, 
round(((vq.titles_audited*1.0)/vp.total_titles_processed *100),2) AS audit_percentage, 
round((100-((vq.critical_defects + vq.non_critical_defects)*1.0)/vq.titles_audited *100),2) AS quality_percentage
FROM vendor_payment vp
JOIN `vendor-ops-analysis.vendor_analysis.vendor_quality_report_2025` vq on vp.vendor_name = vq.vendor_name and vp.month = vq.month)

,yearly_vendor_summary AS (SELECT
vendor_name,
SUM(total_titles_processed) AS total_titles,
SUM(total_cost) AS yearly_cost,
round(AVG(quality_percentage),2) AS avg_quality_percentage,
round(AVG(audit_percentage),2) AS avg_audit_percentage
FROM overall_vendor_analysis
GROUP BY vendor_name
)

,ranked_vendors AS (
SELECT *,
ROUND(yearly_cost / avg_quality_percentage, 2) AS cost_per_quality_point,
DENSE_RANK() OVER (ORDER BY yearly_cost / avg_quality_percentage ASC) AS vendor_rank
FROM yearly_vendor_summary
)

SELECT *,
CASE 
WHEN vendor_rank = 1 THEN 'Best Performer'
WHEN vendor_rank = 2 THEN 'Average Performer'
ELSE 'Needs Review'
END AS vendor_category
FROM ranked_vendors;