require "minitest_helper"

describe Suitcase::Hotel do
  describe "dateless list" do
    before :each do
      @result = Suitcase::Hotel.find(location: "Boston")
    end

    it "returns an Hotel::Result" do
      @result.must_be_kind_of Suitcase::Hotel::Result
    end

    it "offers the raw response" do
      @result.raw.wont_be_nil
    end

    describe "location methods" do
      it "location search is successful" do
        result = Suitcase::Hotel.find(location: "Boston")
        result.wont_be nil
      end

      it "city/state/country search is successful" do
        result = Suitcase::Hotel.find(location: { city: "Boston",
                                                  state: "MA",
                                                  country: "US" })
        result.wont_be nil
      end

      it "destination id search is successful" do
        result = Suitcase::Hotel.find(
          location: { id: "2CEB5C76-BB95-4441-9F33-FFF504434A21" }
        )
        result.wont_be nil
      end

      it "hotel id search is successful" do
        result = Suitcase::Hotel.find(ids: [106347])
        result.wont_be nil
      end

      it "geographical area search is successful" do
        result = Suitcase::Hotel.find(location: { latitude: "33.93",
                                                  longitude: "18.46",
                                                  radius: "10 MI",
                                                  sort: :proximity })
        result.wont_be nil
      end
    end
  end

  describe "availability search" do
    before :each do
      @result = Suitcase::Hotel.find(
        arrival: "03/14/2014",
        departure: "03/21/2014",
        location: "Boston",
        rooms: [{ adults: 1 }],
        include_details: true # necessary for two-step reservation
      )
    end

    it "returns a Hotel::Result" do
      @result.must_be_kind_of Suitcase::Hotel::Result
    end

    describe "room availability" do
      it "returns a reservation" do
        room = @result.value.first.rooms.first
        room.reserve(RESERVATION_HASH)
      end
    end
  end
  
  describe "error handling" do
    before :each do
      begin
        Suitcase::Hotel.find(location: "Some invalid location")
      rescue Suitcase::Hotel::EANException => e
        @exception = e
      end
    end

    it "should raise an exception" do
      assert_raises(Suitcase::Hotel::EANException) do
        Suitcase::Hotel.find(location: "No such place exists")
      end
    end
    
    it "should set the raw API results on the Exception" do
      @exception.raw.wont_be_nil
    end
  end
end

