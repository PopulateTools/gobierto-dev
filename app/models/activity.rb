# frozen_string_literal: true

class Activity < ApplicationRecord
  paginates_per 50

  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :author, polymorphic: true, optional: true
  belongs_to :recipient, polymorphic: true, optional: true
  belongs_to :site, optional: true

  validates :action, presence: true
  validates :subject_ip, presence: true
  validates :admin_activity, inclusion: { in: [true, false] }

  scope :sorted, -> { order(id: :desc) }
  scope :admin, -> { where(admin_activity: true) }
  scope :no_admin, -> { where(admin_activity: false) }
  scope :global, -> { where(site_id: nil) }
  scope :in_site, ->(site_id) { where(site_id: site_id) }
  scope :for_recipient, ->(recipient) { where(recipient: recipient) }

  def self.global_admin_activities
    global.admin.sorted.includes(:subject, :author, :recipient)
  end

  def self.admin_activities(admin)
    where(author_type: admin.class.name, author_id: admin.id).sorted.includes(:subject, :author, :recipient)
  end

  def self.in_participation(current_site)
    processes = current_site.processes.open_process
    Activity.no_admin.where(recipient: processes)
  end

  def self.in_process(process)
    Activity.no_admin.where(recipient: process)
  end
end
