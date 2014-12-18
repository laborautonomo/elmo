# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sms_message, :class => 'Sms::Message' do
    to "MyText"
    from "MyString"
    body "MyText"
    sent_at "2013-04-30 08:52:03"
    type "Sms::Incoming"
  end

  factory :sms_incoming, :class => 'Sms::Incoming', :parent => :sms_message do
  end

  factory :sms_reply, :class => 'Sms::Reply', :parent => :sms_message do
  end

  factory :sms_broadcast, :class => 'Sms::Broadcast', :parent => :sms_message do
  end

  factory :sms_message_with_mission, :parent => :sms_message do
    mission { get_mission }
  end
end
