require 'test_helper'

class RemotePlaceToPayTest < Test::Unit::TestCase
  def setup
    @default_gateway = PlaceToPayGateway.new(fixtures(:place_to_pay_default))

    @amount = 100

    @payer = {
      name: "Erika",
      surname: "Howe",
      email: "cwilliamson@hotmail.com",
      documentType: "CC",
      document: "3572264088",
      mobile: "3006108300"
    }
    payment = {
      description: 'Cum vitae et consequatur quas adipisci ut rem.',
      amount: {
        currency: @default_gateway.default_currency,
        total: @amount
      }
    }
    instrument = {
      card: {
        installments: 1
      }
    }

    @credit_card_approved_diners = credit_card('36545400000008', month: 12, year: 2023, verification_value: '123', first_name: @payer[:name], last_name: @payer[:surname])
    @credit_card_rejected_diners = credit_card('36545400000248', month: 12, year: 2023, verification_value: '123', first_name: @payer[:name], last_name: @payer[:surname])
    @credit_card_approved_visa = credit_card('4110760000000081', month: 12, year: 2023, verification_value: '123', first_name: @payer[:name], last_name: @payer[:surname])
    @credit_card_rejected_visa = credit_card('4110760000000016', month: 12, year: 2023, verification_value: '123', first_name: @payer[:name], last_name: @payer[:surname])
    @credit_card_approved_3DSC_visa = credit_card('4110760000000008', month: 12, year: 2023, verification_value: '123', first_name: @payer[:name], last_name: @payer[:surname])

    @authorize_options = {
      payer: @payer,
      payment: payment,
      instrument: instrument
    }    

    @purchase_options = {
      payer: @payer,
      payment: payment,
      instrument: instrument,
      use3ds: true,
      returnUrl: "https://www.your-site.com/return?reference=1234567890"
    }
    @refund_options = { }
  end
  

  def test_successful_purchase_diners
    @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
    @purchase_options[:use3ds] = false
    @purchase_options[:returnUrl] = nil
    response = @default_gateway.purchase(@amount, @credit_card_approved_diners, @purchase_options)
    assert_success response
    assert_equal 'Aprobada', response.message
  end

  def test_failed_purchase_diners
    @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
    @purchase_options[:use3ds] = false
    @purchase_options[:returnUrl] = nil    
    response = @default_gateway.purchase(@amount, @credit_card_rejected_diners, @purchase_options)
    assert_success response
    assert_equal 'Rechazada', response.message
  end

  def test_successful_purchase_visa
    @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
    @purchase_options[:use3ds] = true
    @purchase_options[:returnUrl] = "https://www.your-site.com/return?reference=1234567890"      
    response = @default_gateway.purchase(@amount, @credit_card_approved_visa, @purchase_options)  
    assert_success response
    assert_equal 'Aprobada', response.message
  end

  def test_failed_purchase_visa
    @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
    @purchase_options[:use3ds] = true
    @purchase_options[:returnUrl] = "https://www.your-site.com/return?reference=1234567890"      
    response = @default_gateway.purchase(@amount, @credit_card_rejected_visa, @purchase_options)
    assert_success response
    assert_equal 'Rechazada', response.message
  end

  def test_successful_refund
    @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
    purchase = @default_gateway.purchase(@amount, @credit_card_approved_visa, @purchase_options)
    assert_success purchase
    assert_equal 'Aprobada', purchase.message

    @refund_options =  { internalReference: purchase.network_transaction_id }
    refund = @default_gateway.refund(@amount, purchase.authorization, @refund_options)

    assert_success refund
    assert_equal 'Aprobada', refund.message
  end

  def test_failed_refund
    @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
    purchase = @default_gateway.purchase(@amount, @credit_card_approved_visa, @purchase_options)
    assert_success purchase
    assert_equal 'Aprobada', purchase.message

    @refund_options =  { internalReference: -1 }
    refund = @default_gateway.refund(@amount, purchase.authorization, @refund_options)

    assert_success refund
    assert_equal 'La referencia interna provista es inválida', refund.message
  end

  def test_already_refunded
    @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
    purchase = @default_gateway.purchase(@amount, @credit_card_approved_visa, @purchase_options)
    assert_success purchase
    assert_equal 'Aprobada', purchase.message

    @refund_options =  { internalReference: purchase.network_transaction_id }
    refund = @default_gateway.refund(@amount, purchase.authorization, @refund_options)

    assert_success refund
    assert_equal 'Aprobada', refund.message

    refund = @default_gateway.refund(@amount, purchase.authorization, @refund_options)
    assert_equal 'La transacción ya ha sido reversada', refund.message

  end

  # def test_dump_transcript
  #   # This test will run a purchase transaction on your gateway
  #   # and dump a transcript of the HTTP conversation so that
  #   # you can use that transcript as a reference while
  #   # implementing your scrubbing logic.  You can delete
  #   # this helper after completing your scrub implementation.
  #   @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
  #   dump_transcript_and_fail(@default_gateway, @amount, @credit_card_approved_visa, @purchase_options)
  # end

  # def test_transcript_scrubbing
  #   transcript = capture_transcript(@default_gateway) do
  #     @purchase_options[:payment][:reference] = "TEST_" + Time.now.strftime("%Y%m%d_%H%M%S%3N")
  #     @default_gateway.purchase(@amount, @credit_card_approved_visa, @purchase_options)
  #   end
  #   transcript = @default_gateway.scrub(transcript)

  #   assert_scrubbed(@credit_card_approved_visa.number, transcript)
  # end
  
end