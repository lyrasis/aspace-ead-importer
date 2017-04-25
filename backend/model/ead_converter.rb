class ImporterEADConverter < EADConverter

  def self.configure
    super
  end # END configure

  # Templates Section

  def make_corp_template(opts)
    return nil if inner_xml.strip.empty?
    make :agent_corporate_entity, {
      :agent_type => 'agent_corporate_entity'
    } do |corp|
      set ancestor(:resource, :archival_object), :linked_agents, {
        'ref' => corp.uri, 'role' => opts[:role], 'relator' => att('role')
      }
    end

    make :name_corporate_entity, {
      :primary_name => inner_xml,
      :rules => att('rules'),
      :authority_id => att('id'),
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_corporate_entity), :names, proxy
    end
  end


  def make_family_template(opts)
    return nil if inner_xml.strip.empty?
    make :agent_family, {
      :agent_type => 'agent_family',
    } do |family|
      set ancestor(:resource, :archival_object), :linked_agents, {
        'ref' => family.uri, 'role' => opts[:role], 'relator' => att('role')
      }
    end

    make :name_family, {
      :family_name => inner_xml,
      :rules => att('rules'),
      :authority_id => att('id'),
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_family), :names, name
    end
  end


  def make_person_template(opts)
    return nil if inner_xml.strip.empty?
    make :agent_person, {
      :agent_type => 'agent_person',
    } do |person|
      set ancestor(:resource, :archival_object), :linked_agents, {
        'ref' => person.uri, 'role' => opts[:role], 'relator' => att('role')
      }
    end

    make :name_person, {
      :name_order => 'inverted',
      :primary_name => inner_xml,
      :authority_id => att('id'),
      :rules => att('rules'),
      :source => att('source') || 'ingest'
    } do |name|
      set ancestor(:agent_person), :names, name
    end
  end

end # END class

::EADConverter
::EADConverter = ImporterEADConverter