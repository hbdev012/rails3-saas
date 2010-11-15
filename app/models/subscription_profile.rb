class SubscriptionProfile < ActiveRecord::Base
  belongs_to :subscription

  validates :payment_auth_id, :card_number, :card_type, :card_holder_name,
    :card_expired_on, :presence => true
  validate :valid_card

  before_validation :store_card!
  before_destroy :unstore_card!

  def card
    @card ||= ActiveMerchant::Billing::CreditCard.new
  end

  def card=(value)
    @card = ActiveMerchant::Billing::CreditCard.new(value)

    self.card_number = @card.display_number
    self.card_type = @card.type
    self.card_holder_name = @card.name
    self.card_expired_on = @card.expiry_date.expiration.to_date

    @card
  end

  def card?
    !!@card
  end

  private

  def gateway
    configatron.gateway.current
  end

  def store_card!
    return unless card? && card.valid?

    store_response = gateway.store(card)
    raise StoreFailed.new(store_response) unless store_response.success?

    self.payment_auth_id = store_response.token
  end

  def unstore_card!
    gateway.unstore(payment_auth_id)
  end

  def valid_card
    return unless card?
    
    unless card.valid?
      errors.add(:card, 'must be valid') and return
    end

    begin
      test_card!
    rescue AuthorizationFailed => e
      errors.add(:card, "failed test charge with: #{e.response.message}")
    end
  end

  # Check out http://letsfreckle.com/blog/2008/12/ecommerce-stuff/
  # Test charges need to be at least $1
  def test_card!
    auth_response = gateway.authorize(100, card)
    gateway.void(auth_response.authorization) if auth_response.success?
    raise AuthorizationFailed.new(auth_response) unless auth_response.success?
  end
end