# frozen_string_literal: true

module API
  module V2
    module OrderHelpers

      def build_order(attrs)
        #Rails.logger.info { "PMC 1 - OrderHelpers build_order" }

        (attrs[:side] == 'sell' ? OrderAsk : OrderBid).new \
          state:         ::Order::PENDING,
          member:        current_user,
          ask:           current_market&.base_unit,
          bid:           current_market&.quote_unit,
          market:        current_market,
          market_type:   ::Market::DEFAULT_TYPE,
          ord_type:      attrs[:ord_type] || 'limit',
          price:         attrs[:price],
          volume:        attrs[:volume],
          origin_volume: attrs[:volume]
      end

      def create_order(attrs)
        create_order_errors = {
          ::Account::AccountError => 'market.account.insufficient_balance',
          ::Order::InsufficientMarketLiquidity => 'market.order.insufficient_market_liquidity',
          ActiveRecord::RecordInvalid => 'market.order.invalid_volume_or_price'
        }

        order = build_order(attrs)

        #Rails.logger.info { "PMC 3 - OrderHelpers create_order" }
        # PMC seems to fail here
        order.submit_order
        #Rails.logger.info { "PMC 4 - OrderHelpers create_order" }
        order
        #Rails.logger.info { "PMC 5 - OrderHelpers create_order" }
        # TODO: Make more specific error message for ActiveRecord::RecordInvalid.
      rescue StandardError => e
        if create_order_errors.include?(e.class)
          report_api_error(e, request)
        else
          report_exception(e)
        end

        message = create_order_errors.fetch(e.class, 'market.order.create_error')
        error!({ errors: [message] }, 422)
      end

      def order_param
        #Rails.logger.info { "PMC 1 - OrderHelpers order_param" }
        params[:order_by].downcase == 'asc' ? 'id asc' : 'id desc'
      end
    end
  end
end
