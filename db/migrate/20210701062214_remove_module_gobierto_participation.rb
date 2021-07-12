class RemoveModuleGobiertoParticipation < ActiveRecord::Migration[6.0]

  def change
    GobiertoModuleSettings.where(module_name: 'GobiertoParticipation').each(&:delete)
    Activity.where(recipient_type: "GobiertoParticipation::Process").each(&:delete)

    GobiertoCommon::CollectionItem.where(item_type: "GobiertoParticipation::Process").each(&:delete)
    GobiertoCommon::CollectionItem.where(item_type: "GobiertoParticipation").each(&:delete)

    GobiertoCommon::Collection.where(container_type: "GobiertoParticipation::Process").each(&:delete)
    GobiertoCommon::Collection.where(container_type: "GobiertoParticipation").each(&:delete)


    drop_table :gpart_comments
    drop_table :gpart_contribution_containers
    drop_table :gpart_contributions
    drop_table :gpart_flags
    drop_table :gpart_poll_answer_templates
    drop_table :gpart_poll_answers
    drop_table :gpart_poll_questions
    drop_table :gpart_polls
    drop_table :gpart_process_stage_pages
    drop_table :gpart_process_stages
    drop_table :gpart_processes
    drop_table :gpart_votes

    Site.all.each do |site|
      site.configuration_data["modules"].delete("GobiertoParticipation")
      site.configuration_data["modules"].first if site.configuration_data["home_page"] == "GobiertoParticipation"
      site.save
    end
  end

end