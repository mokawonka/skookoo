module UserHelper

    def linkify_mentions(text)
        return "" if text.blank?

        content = text.to_s

        # Collect all unique @usernames in the text
        usernames = content.scan(/@(\w+)/).flatten.uniq

        # Single DB query for all mentioned users at once
        users_map = User.where(username: usernames)
                        .select(:id, :username)
                        .index_by(&:username)

        content.gsub(/@(\w+)/) do
        username = $1
        user     = users_map[username]

        if user
            # Known user → styled link with hovercard trigger
            %(<a href="/users/#{username}" ) +
            %(class="user-hover-trigger" ) +
            %(data-user-id="#{user.id}" ) +
            %(style="color:#0951a9;text-decoration:none;font-weight:500;">@#{h(username)}</a>)
        else
            # Unknown user → plain text, no link
            "@#{h(username)}"
        end
        end.html_safe
    end
    
end
