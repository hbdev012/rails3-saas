class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :confirmable,
    :recoverable, :rememberable, :trackable, :validatable, :invitable

  attr_accessible :full_name, :email, :password, :password_confirmation

  belongs_to :account

  def full_name_with_email
    "#{self[:full_name]} (#{email})"
  end

end
