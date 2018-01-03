class ImporterEADConverter < EADConverter

  def self.configure
    super

    eic = AppConfig[:importer][:converter] || {}

    with 'unitid' do |node|
      ancestor(:note_multipart, :resource, :archival_object) do |obj|
        case obj.class.record_type
        when 'resource'
          if eic.has_key? :unitid
            inner_xml.split(/#{eic[:unitid][:split_pattern]}/).each_with_index do |id, i|
              id_x = "id_#{i}".to_sym
              set obj, id_x, eic[:unitid][id_x].call(id)
            end
          else
            set obj, :id_0, inner_xml
          end
        when 'archival_object'
          set obj, :component_id, inner_xml
        end
      end
    end
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

    authorized_name = att('normal')
    display_name_authorized = (authorized_name and authorized_name == inner_xml) ? true : false

    make :name_person, {
      :name_order => 'inverted',
      :primary_name => inner_xml,
      :authority_id => att('id'),
      :rules => att('rules'),
      :source => att('source') || 'ingest',
      :authorized => display_name_authorized,
      :is_display_name => true,
    } do |name|
      set ancestor(:agent_person), :names, name
    end

    if authorized_name and not display_name_authorized
      make :name_person, {
        :name_order => 'inverted',
        :primary_name => att('normal'),
        :authority_id => att('id'),
        :rules => att('rules'),
        :source => att('source') || 'ingest',
        :authorized => true,
        :is_display_name => false,
      } do |name|
        set ancestor(:agent_person), :names, name
      end
    end
  end

end # END class
