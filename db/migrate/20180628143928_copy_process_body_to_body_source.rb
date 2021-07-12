class CopyProcessBodyToBodySource < ActiveRecord::Migration[5.2]
  def change
    if defined? GobiertoParticipation::Process
      ::GobiertoParticipation::Process.all.each do |process|
        process.body_source_translations = process.body_translations
        process.save!
      end
    end
  end
end
