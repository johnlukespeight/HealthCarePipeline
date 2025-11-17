-- Healthcare utility macros for common transformations

{% macro calculate_age(date_of_birth, reference_date=none) %}
  {% if reference_date %}
    date_diff({{ reference_date }}, {{ date_of_birth }}, year)
  {% else %}
    date_diff(current_date(), {{ date_of_birth }}, year)
  {% endif %}
{% endmacro %}

{% macro age_group(age) %}
  case 
    when {{ age }} < 18 then 'Pediatric'
    when {{ age }} between 18 and 64 then 'Adult'
    else 'Senior'
  end
{% endmacro %}

{% macro normalize_phone(phone_number) %}
  replace(replace(replace({{ phone_number }}, '(', ''), ')', ''), '-', '')
{% endmacro %}

{% macro is_valid_email(email) %}
  case 
    when {{ email }} is not null and {{ email }} like '%@%' then true 
    else false 
  end
{% endmacro %}

{% macro is_valid_phone(phone_number) %}
  case 
    when {{ phone_number }} is not null and length({{ normalize_phone(phone_number) }}) >= 10 then true 
    else false 
  end
{% endmacro %}

{% macro categorize_visit_duration(duration_minutes) %}
  case 
    when {{ duration_minutes }} < 30 then 'Short'
    when {{ duration_minutes }} between 30 and 60 then 'Standard'
    else 'Extended'
  end
{% endmacro %}

{% macro categorize_utilization(total_visits) %}
  case 
    when {{ total_visits }} > 10 then 'High Utilizer'
    when {{ total_visits }} between 5 and 10 then 'Moderate Utilizer'
    when {{ total_visits }} between 1 and 4 then 'Low Utilizer'
    else 'No Visits'
  end
{% endmacro %}

{% macro calculate_abnormal_percentage(abnormal_count, total_count) %}
  case 
    when {{ total_count }} > 0 then round({{ abnormal_count }} * 100.0 / {{ total_count }}, 2)
    else 0
  end
{% endmacro %}

{% macro format_currency(amount) %}
  concat('$', format('%0.2f', {{ amount }}))
{% endmacro %}

{% macro days_between(date1, date2) %}
  date_diff({{ date2 }}, {{ date1 }}, day)
{% endmacro %}

{% macro get_quarter(date_column) %}
  concat('Q', cast(extract(quarter from {{ date_column }}) as string), ' ', cast(extract(year from {{ date_column }}) as string))
{% endmacro %}
