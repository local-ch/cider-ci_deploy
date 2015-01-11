# {{ansible_managed}}
#
#

test_spec= Specification.find_or_create_by_data!({
  "_cider-ci_include" =>  "cider-ci/test_spec.yml"
  })
Definition.find_by(name: "Tests").try(&:destroy)
Definition.create name: "Tests" ,
  description: "Loads the specification from the repository path 'cider-ci/test_spec.yml'.",
  specification: test_spec, is_default: true

show_info_spec= Specification.find_or_create_by_data!(
  YAML.load_file Rails.root.join("spec","data","execution-spec-v2_show-info-example.yml"))
Definition.find_by(name: "Show info").try(&:destroy)
Definition.create name: "Show info" ,
  description: "Information about project, machine and os",
  specification: show_info_spec

if User.where(is_admin: true).count == 0
  User.create!(login: '{{system_admin_login}}', is_admin: true) 
end

{% if system_admin_password is defined %}
User.find_or_create_by!({ login: '{{system_admin_login}}'}) \
  .update_attributes(is_admin: true, password: '{{system_admin_password}}')
{% endif %}

{% for executor in groups['cider-ci-executors'] %}
executor=Executor.find_or_initialize_by(name: "{{executor}}")

executor.update_attributes!(
  host: "{{hostvars[executor]['ansible_default_ipv4']['address']}}",
  port: "{{executor_service_https_port}}", 
  ssl: true
)

executor.reload

traits= (executor.traits || []).concat([
  {% for trait in traits %}
    '{{trait}}',
  {% endfor %}
  ]).sort.uniq

executor.reload.update_attributes! traits: traits

User.find_or_create_by(login: '{{hostvars[executor]['api_username']}}') \
  .update_attributes!(password: '{{hostvars[executor]['api_password']}}')
  
{% endfor %}


repo= Repository.find_or_initialize_by name: "Cider-CI Bash Demo Project"
repo.update_attributes! \
  origin_uri: 'https://github.com/cider-ci/cider-ci_demo-project-bash.git'


welcome_page_settings= WelcomePageSettings.find

if welcome_page_settings.welcome_message.blank? 
  welcome_page_settings.update_attributes! \
    welcome_message: "# Welcome to your installation of Cider-CI"
end

  
if welcome_page_settings.radiator_config.blank? 
  radiator_config= YAML.load_file \
    Rails.root.join("db", "initial_radiator_config.yml")
  welcome_page_settings.update_attributes! \
    radiator_config: radiator_config
end
  




