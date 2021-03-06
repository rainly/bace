require File.dirname(__FILE__) + '/../test_helper'

class PermissionTest < ActiveSupport::TestCase
  def setup
    @permission = Factory(:permission)
  end
  
  should_have_db_column :name
  should_have_db_column :parent_id
  should_have_db_column :lft
  should_have_db_column :rgt
  should_have_db_column :remark
  should_have_db_column :public
  should_have_db_column :free

  should_have_many :permissions_roles
  should_have_many :roles
  should_have_many :resources
  should_have_many :klasses_permissions
  should_have_many :klasses

  should_have_instance_methods :can_public?, :can_free?, :granted_to_role?, :limits_to_role
  should "可以继承上级的public定义" do
    child = Factory(:permission, :name => 'child')
    child.move_to_child_of(@permission)
    assert_nil child.can_public?
    @permission.update_attribute(:public, true)
    assert child.can_public?
    @permission.update_attribute(:public, false)
    assert_equal child.can_public?, false
    @permission.update_attribute(:public, nil)
    child.update_attribute(:public, true)
    assert child.can_public?
  end

  should "判断是否某角色拥有本权限" do
    role = Factory(:role)
    assert_nil @permission.granted_to_role?(role)
    role.permissions << @permission
    assert_nil @permission.granted_to_role?(role)
    permissions_role = role.permissions_roles.first
    permissions_role.update_attribute(:granted, true)
    assert @permission.granted_to_role?(role)
    permissions_role.update_attribute(:granted, false)
    assert_equal @permission.granted_to_role?(role), false
  end

  should "可以继承上级的free定义" do
    child = Factory(:permission, :name => 'child')
    child.move_to_child_of(@permission)
    assert_nil child.can_free?
    @permission.update_attribute(:free, true)
    assert child.can_free?
    @permission.update_attribute(:free, false)
    assert_equal child.can_free?, false
    @permission.update_attribute(:free, nil)
    child.update_attribute(:free, true)
    assert child.can_free?
  end

  should "得到role针对本permission的scope定义" do
    role = Factory(:role)
    klass = Factory(:klass)
    permissions_role = Factory(:permissions_role, :permission => @permission, :role => role)
    meta = Factory(:meta, :klass => klass)
    limit_group = Factory(:limit_group, :klass => klass)
    Factory(:limit_scope, :key_meta => meta, :target_klass => klass, :limit_group => limit_group)
    limit_group.permissions_roles << permissions_role
    assert @permission.limits_to_role(klass, role), limit_group
  end

end
