# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/../test_helper'

class FeedControllerTest < ActionController::TestCase

  def test_read_feed
    feed_name = CompetitionData.instance.name
    feed_description = "#{feed_name} News"
    get :news
    assert_select_feed :rss, 2.0 do
      assert_select 'channel' do
        assert_select 'title', :count => 1, :text => feed_name
        assert_select 'description', :count => 1, :text => feed_description
        assert_select 'item', 5
        10.downto(6) do |n|
          assert_select "item:nth-last-child(#{n-5})" do
            assert_select 'title', :count => 1, :text => "News Item #{n}"
            assert_select 'link', /^http/
            assert_select 'guid', /^http/
            assert_select 'description', :count => 1 do
              assert_select_encoded do
                assert_select 'p', :count => 1, :text => "Contents of item #{n}"
              end
            end
          end
        end
      end
    end
  end

end
