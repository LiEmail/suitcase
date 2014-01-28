module Suitcase
  # Public: Class for doing Hotel operations in the EAN API.
  class Hotel
    # Internal: List of possible amenities and their masks as returned by the
    #           API.
    AMENITIES = {
      business_center: 1,
      fitness_center: 2,
      hot_tub: 4,
      internet_access: 8,
      kids_activities: 16,
      kitchen: 32,
      pets_allowed: 64,
      swimming_pool: 128,
      restaurant: 256,
      spa: 512,
      whirlpool_bath: 1024,
      breakfast: 2048,
      babysitting: 4096,
      jacuzzi: 8192,
      parking: 16384,
      room_service: 32768,
      accessible_path: 65536,
      accessible_bathroom: 131072,
      roll_in_shower: 262144,
      handicapped_parking: 524288,
      in_room_accessibility: 1048576,
      deaf_accessiblity: 2097152,
      braille_or_raised_signage: 4194304,
      free_airport_shuttle: 8388608,
      indoor_pool: 16777216,
      outdoor_pool: 33554432,
      extended_parking: 67108864,
      free_parking: 134217728
    }

    class << self
      # Public: Find hotels matching the search query.
      #
      # There are two main types of queries. An availability search, which
      # requires dates, rooms, and a destination to search. The other is a
      # 'dateless' search, which finds all hotels in a given area.
      #
      # params - A Hash of search query parameters:
      #           :arrival            - String date of arrival, written
      #                                 MM/DD/YYYY (defult: nil).
      #           :departure          - String date of departure, written
      #                                 MM/DD/YYYY (default: nil).
      #           :number_of_results  - Number of results to return
      #                                 (default: 20). Does not apply to
      #                                 dateless requests.
      #           :rooms              - An Array of Hashes, within each Hash
      #                                 (default: nil):
      #                                 :adults   - Number of adults in the
      #                                             room.
      #                                 :children - Array of childrens' ages in
      #                                             the room. (default: [])
      #           :include_details    - Boolean. Include extra information with
      #                                 each room option.
      #           :location           - A String or Hash location to search by.
      # Examples:
      #
      #   Hotel.find(location: "Boston")
      #   # => #<Result [all hotels in Boston as Hotel objects]>
      #
      #   Hotel.find(arrival: "03/14/2014", departure: "03/21/2014"
      #              location: "Boston", rooms: [{ adults: 1}])
      #   # => #<Result [all hotels in Boston with their rooms available from
      #                 14 Mar 2014 to 21 Mar 2014]>
      #
      # Returns a Result with the search results.
      def find(params)
        if params[:arrival]
          availability_search(params)
        else
          dateless_search(params)
        end
      end

      # Internal: Run an availability search for Hotels.
      #
      # params - A Hash of search query parameters, unchanged from the find
      #           method:
      #           :arrival            - String date of arrival, written
      #                                 MM/DD/YYYY.
      #           :departure          - String date of departure, written
      #                                 MM/DD/YYYY.
      #           :number_of_results  - Integer number of results to return.
      #           :rooms              - An Array of Hashes, within each Hash:
      #                                 :adults   - Integer number of adults in
      #                                             the room.
      #                                 :children - Array of childrens' Integer
      #                                             ages in the room.
      #           :include_details    - Boolean. Whether to include extra
      #                                 information with each room option, such
      #                                 as bed types.
      #           :fee_breakdown      - Boolean. Whether to include fee
      #                                 breakdown information with room results.
      #
      # Returns a Result with search results.
      def availability_search(params)
        req_params = Room.room_group({
          arrivalDate: params[:arrival],
          departureDate: params[:departure],
          numberOfResults: params[:number_of_results],
          includeDetails: params[:include_details],
          includeHotelFeeBreakdown: params[:fee_breakdown],
          includeSurrounding: params[:include_surrounding]
        }, params[:rooms])
        if params[:ids]
          req_params[:hotelIds] = params[:ids].join(",")
        elsif params[:location]
          req_params = location_params(req_params, params[:location])
        end

        hotel_list(req_params)
      end

      # Internal: Run a 'dateless' search for Hotels.
      #
      # params - A Hash of search query parameters, generally just a location:
      #           :location - String user-inputted location.
      #
      # Returns a Result with search results.
      def dateless_search(params)
        if params[:location]
          req_params = location_params({
            includeSurrounding: params[:include_surrounding]
          }, params[:location])
          hotel_list(req_params)
        elsif params[:ids]
          hotel_list(hotelIdList: params[:ids].join(","))
        end
      end

      # Internal: Complete the request for a Hotel list.
      #
      # req_params - A Hash of search query parameters, as modified by the used
      #               search function:
      #               :arrivalDate              - String date of arrival
      #                                           (default: nil).
      #               :departureDate            - String date of departure
      #                                           (default: nil).
      #               :numberOfResults          - Integer number of Hotel
      #                                           results.
      #               :RoomGroup                - String. Formatted according to
      #                                           EAN API spec to describe
      #                                           desired rooms.
      #               :includeDetails           - Boolean. Whether to include
      #                                           extra details in each room
      #                                           option.
      #               :includeHotelFeeBreakdown - Boolean. Whether to include
      #                                           a room fee breakdown for each
      #                                           room option.
      #
      # Returns a Result with search results.
      def hotel_list(req_params)
        req_params[:cid] = Suitcase::Configuration.ean_hotel_cid
        req_params[:apiKey] = Suitcase::Configuration.ean_hotel_api_key
        req_params[:minorRev] = Suitcase::Configuration.ean_hotel_minor_rev
        req_params = req_params.delete_if { |k, v| v == nil }

        Result.new("/ean-services/rs/hotel/v3/list", req_params) do |res|
          [res.url, res.body, parse_hotel_list(res.body)]
        end
      end

      # Internal: Parse the location search options for the API call.
      #
      # params    - Hash of existing request parameters.
      # location  - Hash or String of location information.
      #
      # Returns an updated set of parameters to be passed to the API call as a
      # Hash.
      def location_params(params, location)
        req_params = params.clone
        if location.is_a?(String)
          req_params[:destinationString] = location
        elsif location.is_a?(Hash)
          if location.keys.include?(:city)
            req_params[:city] = location[:city]
            if location[:state]
              req_params[:stateProvinceCode] = location[:state]
            end
            req_params[:countryCode] = location[:country]
            if location[:address]
              req_params[:address] = location[:address]
              if location[:postal_code]
                req_params[:postalCode] = location[:postal_code]
              end
            end
            req_params[:propertyName] = location[:name] if location[:name]
          elsif location.keys.include?(:id)
            req_params[:destinationId] = location[:id]
          elsif location.keys.include?(:latitude)
            req_params[:latitude] = location[:latitude]
            req_params[:longitude] = location[:longitude]
            req_params[:searchRadius] = location[:radius]
            req_params[:searchRadiusUnit] = location[:radius_unit]
            req_params[:sort] = location[:sort].to_s
          end
        end

        req_params
      end

      # Internal: Parse the results of a Hotel list call.
      #
      # body - String body of the response from the call.
      #
      # Returns an Array of Hotels based on the search results.
      # Raises Suitcase::Hotel::EANEexception if the EAN API returns an error.
      def parse_hotel_list(body)
        root = JSON.parse(body)["HotelListResponse"]

        if error = root["EanWsError"]
          handle(error)
        else hotels = [root["HotelList"]["HotelSummary"]].flatten
          hotels.map do |data|
            Hotel.new do |hotel|
              hotel.id = data["hotelId"]
              hotel.name = data["name"]
              hotel.address = data["address1"]
              if data["address2"]
                hotel.address = [hotel.address, data["address2"]].join(", ")
              end
              hotel.city = data["city"]
              hotel.province = data["stateProvinceCode"]
              hotel.postal = data["postalCode"]
              hotel.country = data["countryCode"]
              hotel.airport = data["airportCode"]
              hotel.category = data["propertyCategory"]
              hotel.rating = data["hotelRating"]
              hotel.confidence_rating = data["confidenceRating"]
              hotel.amenities = parse_amenities(data["amenityMask"])
              hotel.tripadvisor_rating = data["tripAdvisorRating"]
              hotel.location_description = data["locationDescription"]
              hotel.short_description = data["shortDescription"]
              hotel.high_rate = data["highRate"]
              hotel.low_rate = data["lowRate"]
              hotel.currency = data["rateCurrencyCode"]
              hotel.latitude = data["latitude"]
              hotel.longitude = data["longitude"]
              hotel.proximity_distance = data["promixityDistance"]
              hotel.proximity_unit = data["proximityUnit"]
              hotel.in_destination = data["hotelInDestination"]
              hotel.thumbnail_path = data["thumbNailUrl"]
              hotel.ian_url = data["deepLink"]
              if data["RoomRateDetailsList"]
                hotel.rooms = parse_rooms(data["RoomRateDetailsList"])
              end
            end
          end
        end
      end
      
      # Internal: Parse room data from a Hotel response.
      #
      # room_details - Hash of room details returned by the API.
      #
      # Returns an Array of Rooms.
      def parse_rooms(room_details)
        rate_details = [room_details["RoomRateDetails"]].flatten
        rate_details.map { |rd| Room.new(rd) }
      end
        
      # Internal: Handle errors returned by the API.
      #
      # error - The parsed error Hash returned by the API.
      #
      # Raises an EANException with the parameters returned by the API.
      def handle(error)
        message = error["presentationMessage"]
      
        e = EANException.new(message)
        if error["itineraryId"] != -1
          e.reservation_made = true
          e.reservation_id = error["itineraryId"]
        end
        e.verbose_message = error["verboseMessage"]
        e.recoverability = error["handling"]
        e.raw = error
        
        raise e
      end
      
      # Internal: Parse the amenities of a Hotel.
      #
      # mask - Integer mask of the amenities.
      #
      # Returns an Array of Symbol amenities, as from the Hotel::Amenity Hash.
      def parse_amenities(mask)
        AMENITIES.select { |amenity, amask| (mask & amask) > 0 }.keys
      end
    end

    attr_accessor :id, :name, :address, :city, :province, :postal, :country,
                  :airport, :category, :rating, :confidence_rating,
                  :amenities, :tripadvisor_rating, :location_description,
                  :short_description, :high_rate, :low_rate, :currency,
                  :latitude, :longitude, :proximity_distance, :proximity_unit,
                  :in_destination, :thumbnail_path, :ian_url

    attr_writer :rooms

    # Internal: Create a new Hotel.
    #
    # block - Required. Should accept the hotel object itself to set attributes
    #         on.
    def initialize
      yield self
    end

    # Public: Access returned rooms or search for rooms.
    #
    # rooms - An optional Array of Hashes, to be used only if searching for
    #         rooms. Each Hash has the following keys:
    #         :adults   - The number of adults in that room.
    #         :children - An Array of the ages of children in that room.
    #
    # Returns a Room.
    def rooms(rooms = [])
      if @rooms
        @rooms
      else
        room_search(rooms)
      end
    end

    # Internal: A small wrapper around the results of an EAN API call.
    class Result
      attr_reader :url, :params, :raw, :value

      # Internal: Create a new Result.
      #
      # path        - String path of the request to be used with the API base
      #               URL.
      # req_params  - Hash of the params used in the request.
      # parser      - A block that should take the HTTP response and return the
      #               request URL, the string response, and the Result value.
      def initialize(path, req_params, &parser)
        req = Patron::Session.new
        params_string = req_params.inject("") do |initial, (key, value)|
          value = (value == true ? "true" : value)
          initial + if value
                      req.urlencode(key.to_s) + "=" + req.urlencode(value) + "&"
                    else
                      ""
                    end
        end
        req.timeout = 30
        req.base_url = "http://api.ean.com"

        res = req.get([path, params_string].join("?"))
        
        @url, @raw, @value = parser.call(res)
      end
    end
    
    # Internal: The general Exception class for Exceptions caught form the Hotel
    #           API.
    class EANException < Exception
      # Public: The raw error returned by the API.
      attr_accessor :raw
      
      # Public: The verbose message returned by the API.
      attr_accessor :verbose_message
      
      # Public: The ID of the reservation made in the errant request if a
      #         reservation completed.
      attr_accessor :reservation_id

      # Public: The recoverability of the error (direct from the) API.
      attr_accessor :recoverability
      
      # Internal: Writer for the boolean whether a reservation was made.
      attr_writer :reservation_made
      
      # Public: Reader for the boolean whether a reservation was made. If a
      #         reservation was completed `reservation_id' will contain the
      #         reservation ID.
      def reservation_made?
        @reservation_made
      end
    end
    
    # Internal: Representation of room availability as returned by the API.
    class Room
      Promotion = Struct.new(:id, :description, :details)

      attr_accessor :room_type_code, :rate_code, :rate_key, :max_occupancy,
                    :quoted_occupancy, :minimum_age, :description, :promotion,
                    :allotment, :available, :restricted, :expedia_id

      def initialize(room_details)
        @room_type_code = room_details["roomTypeCode"]
        @rate_code = room_details["rateCode"]
        @rate_key = room_details["rateKey"]
        @max_occupancy = room_details["maxRoomOccupancy"]
        @quoted_occupancy = room_details["quotedRoomOccupancy"]
        @minimum_age = room_details["minGuestAge"]
        @description = room_details["roomDescription"]
        if room_details["promoId"]
          promotion = Promotion.new(
            room_details["promoId"],
            room_details["promoDescription"],
            room_details["promoDetailText"]
          )
        end
        @allotment = room_details["currentAllotment"]
        @available = room_details["propertyAvailable"]
        @restricted = room_details["propertyRestricted"]
        @expedia_id = room_details["expediaPropertyId"]
      end

      # Internal: Format the room group expected by the EAN API.
      #
      # req_params  - The request parameters already set.
      # rooms       - Array of Hashes:
      #               :adults   - Integer number of adults in the room.
      #               :children - Array of children ages in the room
      #                           (default: []).
      #
      # Returns a Hash of request parameters.
      def self.room_group(req_params, rooms)
        rooms.each_with_index do |room, index|
          room_n = index + 1
          req_params["room#{room_n}"] = [room[:adults], room[:children]].
                                        flatten.join(",")
        end

        req_params
      end

      # Public: Reserve previously returned rooms.
      #
      # params  - A Hash of parameters to be passed to the API, with the
      #           following required keys:
      #           :first_name - The first name of the credit-card holder.
      #           :last_name  - The last name of the credit-card holder.
      #           :email      - The email address of the customer.
      #           :home_phone - The home phone of the customer.
      #           :work_phone - The work phone of the customer.
      #           :extension  - The work phone extension of the customer. 5-char
      #                         max.
      #           :fax_phone  - The fax number of the customer.
      #           :company    - The name of the company.
      #           :emails     - Additional emails to send the reservation
      #                         confirmation to.
      #           :card       - A Hash of information about the customer's
      #                         credit card with the following keys:
      #                         :type       - The credit card type.
      #                         :number     - The card's number
      #                         :csv        - The CSV of the card.
      #                         :expiration - The expiration of the card, as
      #                                       MM/YYYY.
      #           :address    - An Array of billing address lines. Maximum
      #                         length of 3.
      #           :city       - Billing address city.
      #           :state      - The state/province code, if applicable.
      #           :country    - The 2-char ISO-3166 country code in the billing
      #                         address.
      #           :postal_code- The postal code in the billing address.
      #           :rooms      - The array of room objects passed to either
      #                         Hotel.find or Hotel#rooms, with additional
      #                         fields:
      #                         :bed_type           - The ID of the desired bed
      #                                               type. Choices are listed
      #                                               in the room response.
      #                         :smoking_preference - The smoking preference for
      #                                               the room. Choices are
      #                                               listed in the room
      #                                               response.
      #                         :first_name         - The first name of the
      #                                               adult who will be checking
      #                                               in to the room.
      #                         :last_name          - The last name of the adult
      #                                               who will be checking in to
      #                                               the room.
      #                         :number_of_beds     - The number of beds for the
      #                                               room, to be based off the
      #                                               room response.
      #                         :frequent_guest_id  - A frequent guest number,
      #                                               to be used only with Hotel
      #                                               collect properties.
      #                         :itinerary_id       - To be used in the event of
      #                                               a credit card validation
      #                                               error, in order to prevent
      #                                               duplicate itineraries.
      #                         :special_info       - Any custom info added by
      #                                               the customer. 256-char
      #                                               max.
      #                         :affiliate_confirmation_id  - A unique generated
      #                                                       value to be used
      #                                                       for tracking the
      #                                                       itinerary. 36-char
      #                                                       max.
      #                         :affiliate_customer_id  - A unique generated
      #                                                   value to be used to
      #                                                   track individual
      #                                                   customers internally.
      def reserve(params)
      end
    end
  end
end

