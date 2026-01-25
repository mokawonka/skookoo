module DeliveryMethods
    class TurboBroadcast < Noticed::DeliveryMethods::Base


      def deliver

        Turbo::StreamsChannel.broadcast_prepend_to(
          notification.recipient,
          target:  "notifications-popup",
          partial: "notifications/popup",          # → app/views/notifications/_popup.html.erb
          locals:  { notification: notification }  # pass whatever your partial needs
        )

        Turbo::StreamsChannel.broadcast_prepend_to(
          notification.recipient,
          target:  "notifications-dropdown",
          partial: "notifications/notification",   # → app/views/notifications/_notification.html.erb
          locals:  { notification: notification }  # pass whatever your partial needs
        )

          count = notification.recipient.notifications.unread.count

          Turbo::StreamsChannel.broadcast_update_to(
            notification.recipient,
            target: "notification-count",
            partial: "notifications/notification_count",
            locals: { count: count }
          )

          Turbo::StreamsChannel.broadcast_action_to(
            notification.recipient,
            action: :play_notification_sound,
            target: "body"   # target is required but ignored in this custom action
          )

      end


    end
  end
