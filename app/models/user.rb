# == Schema Information
#
# Table name: users
#
#  id                     :bigint(8)        not null, primary key
#  accepted_privacy_at    :datetime
#  accepted_terms_at      :datetime
#  admin                  :boolean
#  announcements_read_at  :datetime
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :integer          default(0)
#  invited_by_type        :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  time_zone              :string
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :bigint(8)
#
# Indexes
#
#  index_users_on_email                              (email) UNIQUE
#  index_users_on_invitation_token                   (invitation_token) UNIQUE
#  index_users_on_invitations_count                  (invitations_count)
#  index_users_on_invited_by_id                      (invited_by_id)
#  index_users_on_invited_by_type_and_invited_by_id  (invited_by_type,invited_by_id)
#  index_users_on_reset_password_token               (reset_password_token) UNIQUE
#

class User < ApplicationRecord
  include ActionText::Attachable

  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, andle :trackable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :confirmable, :invitable, :masqueradable,
    :omniauthable

  include UserAccounts
  include UserAgreements

  has_person_name

  include PgSearch::Model
  pg_search_scope :search_by_full_name, against: [:first_name, :last_name], using: {tsearch: {prefix: true}}

  # ActiveStorage Associations
  has_one_attached :avatar

  # Associations
  has_many :api_tokens, dependent: :destroy
  has_many :connected_accounts, dependent: :destroy

  # We don't need users to confirm their email address on create,
  # just when they change it
  before_create :skip_confirmation!

  belongs_to :referred_by, class_name: "User", optional: true
  has_many :referred_users, class_name: "User", foreign_key: :referred_by_id

  before_create :set_referral_code
  after_create :complete_referral!

  # Validations
  validates :name, presence: true
  validates :referral_code, uniqueness: true

  def set_referral_code
    loop do
      self.referral_code = SecureRandom.hex(6)
      break unless self.class.exists?(referral_code: referral_code)
    end
  end

  def complete_referral!
    update(referral_completed_at: Time.zone.now)
    # Add credit to the referred_by user
  end
end
