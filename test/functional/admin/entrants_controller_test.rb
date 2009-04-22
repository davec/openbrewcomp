# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../../test_helper'

class Admin::EntrantsControllerTest < ActionController::TestCase

  def setup
    login_as(:admin)
    @good_entrant = entrants(:Individual_US)
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'create'
  end

  def test_create
    assert_difference 'Entrant.count' do
      post :create, :record => { :team_name => 'The Bruces',
                                 :is_team => true,
                                 :address1 => '91 Carrion St',
                                 :city => 'Wagga Wagga',
                                 :region => { :id => regions(:AU_QLD).id },
                                 :postcode => '4321',
                                 :email => 'bruce@thebruces.com.au',
                                 :club => { :id => clubs(:independent).id } }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_create_with_existing_club_of_different_case
    # Should not create another club with different case
    assert_no_difference 'Club.count' do
      post :create, :record => { :first_name => 'LOUD',
                                 :last_name => 'BREWER',
                                 :address1 => '981 SHADY LANE',
                                 :city => 'HOUSTON',
                                 :region => { :id => regions(:US_TX).id },
                                 :postcode => '77021',
                                 :phone => '713-555-4000',
                                 :club => { :id => Club.other.id },
                                 :club_name => clubs(:rangers).name.upcase }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_create_with_new_club
    assert_difference 'Club.count' do
      post :create, :record => { :first_name => 'A',
                                 :last_name => 'Brewer',
                                 :address1 => '981 Shady Lane',
                                 :city => 'Houston',
                                 :region => { :id => regions(:US_TX).id },
                                 :postcode => '77021',
                                 :phone => '713-555-4000',
                                 :club => { :id => Club.other.id },
                                 :club_name => 'A New Club' }
    end
    assert assigns(:record).valid?
    assert_redirected_to :action => 'index'
  end

  def test_search
    get :update_table, :search => 'Brewer'
    assert_response :success
    assert_template '_list'
  end

  def test_show
    get :show, :id => @good_entrant.id
    assert_response :success
    assert_template 'show'
  end

  def test_edit
    get :edit, :id => @good_entrant.id
    assert_response :success
    assert_template 'update'
  end

  def test_update
    record = entrants(:Individual_US)
    assert_no_difference 'Entrant.count' do
      post :update, :id => record.id,
                    :record => { :last_name => "#{record.last_name} Jr." }
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_delete
    record = @good_entrant
    assert_difference('Entrant.count', -1) do
      delete :destroy, :id => record.id
    end
    assert_redirected_to :action => 'index', :id => record.id
  end

  def test_help
    get :help
    assert_response :success
    assert_template 'help'
  end

end
