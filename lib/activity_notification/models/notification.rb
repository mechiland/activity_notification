module ActivityNotification
  class Notification < ActiveRecord::Base
    include Renderable
    include Common
    include NotificationApi
    self.table_name = ActivityNotification.config.table_name
  
    # Belongs to target instance of this notification as polymorphic association.
    # @scope instance
    # @return [Object] Target instance of this notification
    belongs_to :target,        polymorphic: true

    # Belongs to notifiable instance of this notification as polymorphic association.
    # @scope instance
    # @return [Object] Notifiable instance of this notification
    belongs_to :notifiable,    polymorphic: true

    # Belongs to group instance of this notification as polymorphic association.
    # @scope instance
    # @return [Object] Group instance of this notification
    belongs_to :group,         polymorphic: true

    # Belongs to group owner notification instance of this notification.
    # Only group member instance has :group_owner value.
    # Group owner instance has nil as :group_owner association.
    # @scope instance
    # @return [Notification] Group owner notification instance of this notification
    belongs_to :group_owner,   class_name: :Notification

    # Has many group member notification instances of this notification.
    # Only group owner instance has :group_members value.
    # Group member instance has nil as :group_members association.
    # @scope instance
    # @return [Array] Array or database query of the group member notification instances of this notification
    has_many   :group_members, class_name: :Notification, foreign_key: :group_owner_id

    # Belongs to :otifier instance of this notification.
    # @scope instance
    # @return [Object] Notifier instance of this notification
    belongs_to :notifier,      polymorphic: true

    # Serialize parameters Hash
    serialize  :parameters, Hash

    validates  :target,        presence: true
    validates  :notifiable,    presence: true
    validates  :key,           presence: true

    # Selects group owner notifications only.
    # @scope class
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :group_owners_only,                 ->        { where(group_owner_id: nil) }

    # Selects group member notifications only.
    # @scope class
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :group_members_only,                ->        { where.not(group_owner_id: nil) }

    # Selects unopened notifications only.
    # @scope class
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :unopened_only,                     ->        { where(opened_at: nil) }

    # Selects unopened notification index.
    # Defined same as `unopened_only.group_owners_only.latest_order`.
    # @example Get unopened notificaton index of the @user
    #   @notifications = @user.unopened_index
    # @scope class
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :unopened_index,                    ->        { unopened_only.group_owners_only.latest_order }

    # Selects opened notifications only without limit.
    # Be careful to get too many records with this method.
    # @scope class
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :opened_only!,                      ->        { where.not(opened_at: nil) }

    # Selects opened notifications only with limit.
    # @scope class
    # @param [Integer] limit Limit to query for opened notifications
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :opened_only,                       ->(limit) { opened_only!.limit(limit) }

    # Selects unopened notification index.
    # Defined same as `opened_only(limit).group_owners_only.latest_order`.
    # @scope class
    # @param [Integer] limit Limit to query for opened notifications
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :opened_index,                      ->(limit) { opened_only(limit).group_owners_only.latest_order }

    # Selects group member notifications in unopened_index.
    # @scope class
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :unopened_index_group_members_only, ->        { where(group_owner_id: unopened_index.pluck(:id)) }

    # Selects group member notifications in opened_index.
    # @scope class
    # @param [Integer] limit Limit to query for opened notifications
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :opened_index_group_members_only,   ->(limit) { where(group_owner_id: opened_index(limit).map(&:id)) }

    # Selects filtered notifications by target instance.
    #   ActivityNotification::Notification.filtered_by_target(@user)
    # is the same as
    #   @user.notifications
    # @scope class
    # @param [Object] target Target instance for filter
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :filtered_by_target,   ->(target)             { where(target: target) }

    # Selects filtered notifications by notifiable instance.
    # @example Get filtered unopened notificatons of the @user for @comment as notifiable
    #   @notifications = @user.notifications.unopened_only.filtered_by_instance(@comment)
    # @scope class
    # @param [Object] notifiable Notifiable instance for filter
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :filtered_by_instance, ->(notifiable)         { where(notifiable: notifiable) }

    # Selects filtered notifications by notifiable_type.
    # @example Get filtered unopened notificatons of the @user for Comment notifiable class
    #   @notifications = @user.notifications.unopened_only.filtered_by_type('Comment')
    # @scope class
    # @param [String] notifiable_type Notifiable type for filter
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :filtered_by_type,     ->(notifiable_type)    { where(notifiable_type: notifiable_type) }

    # Selects filtered notifications by group instance.
    # @example Get filtered unopened notificatons of the @user for @article as group
    #   @notifications = @user.notifications.unopened_only.filtered_by_group(@article)
    # @scope class
    # @param [Object] group Group instance for filter
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :filtered_by_group,    ->(group)              { where(group: group) }

    # Selects filtered notifications by key.
    # @example Get filtered unopened notificatons of the @user with key 'comment.reply'
    #   @notifications = @user.notifications.unopened_only.filtered_by_key('comment.reply')
    # @scope class
    # @param [String] key Key of the notification for filter
    # @return [Array | ActiveRecord_AssociationRelation] Array or database query of filtered notifications
    scope :filtered_by_key,      ->(key)                { where(key: key) }

    # Includes target instance with query for notifications.
    # @return [ActiveRecord_AssociationRelation] Database query of notifications with target
    scope :with_target,                       ->        { includes(:target) }

    # Includes notifiable instance with query for notifications.
    # @return [ActiveRecord_AssociationRelation] Database query of notifications with notifiable
    scope :with_notifiable,                   ->        { includes(:notifiable) }

    # Includes group instance with query for notifications.
    # @return [ActiveRecord_AssociationRelation] Database query of notifications with group
    scope :with_group,                        ->        { includes(:group) }

    # Includes notifier instance with query for notifications.
    # @return [ActiveRecord_AssociationRelation] Database query of notifications with notifier
    scope :with_notifier,                     ->        { includes(:notifier) }

    # Orders by latest (newest) first as created_at: :desc.
    # @return [ActiveRecord_AssociationRelation] Database query of notifications ordered by latest first
    scope :latest_order,                      ->        { order(created_at: :desc) }

    # Orders by earliest (older) first as created_at: :asc.
    # @return [ActiveRecord_AssociationRelation] Database query of notifications ordered by earliest first
    scope :earliest_order,                    ->        { order(created_at: :asc) }

    # Returns latest notification instance.
    # @return [Notification] Latest notification instance
    scope :latest,                            ->        { latest_order.first }

    # Returns earliest notification instance.
    # @return [Notification] Earliest notification instance
    scope :earliest,                          ->        { earliest_order.first }
  end
end
