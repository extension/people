# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AppActivity < ActiveRecord::Base
  serialize :additionaldata
  extend DateTools

  # tracked applications
  APP_ARTICLES  = 100
  APP_ASK       = 200
  APP_PUBLISH   = 300
  APP_CREATE    = 400
  APP_HOMEPAGE  = 500
  APP_LEARN     = 600
  APP_MILFAM    = 700
  APP_PEOPLE    = 800

  # source types
  APP_PUBLISH_POSTS = 301
  APP_PUBLISH_COMMENTS = 302

  APP_HOMEPAGE_POSTS = 301
  APP_HOMEPAGE_COMMENTS = 302

  APP_LEARN_EVENT_ACTIVITY = 601
  APP_LEARN_VERSIONS = 602

  APP_CREATE_REVISIONS = 401
  APP_CREATE_WORKFLOW_EVENTS = 402
  APP_CREATE_COMMENTS = 403

  APP_ASK_QUESTIONEVENTS = 201

  # APP_PEOPLE_ACTIVITY    = 801


  # tracked application labels
  APP_LABELS = {
    APP_ARTICLES => 'articles',
    APP_ASK => 'ask',
    APP_CREATE => 'create',
    APP_HOMEPAGE => 'homepage',
    APP_LEARN => 'learn',
    APP_MILFAM => 'milfam',
    APP_PEOPLE => 'people',
    APP_PUBLISH => 'publish'
  }

  # activities
  ACTIVITY_OTHER = 1
  ACTIVITY_EDIT = 2
  ACTIVITY_COMMENT = 3
  ACTIVITY_BOOKMARK = 4
  ACTIVITY_ATTEND = 5
  ACTIVITY_WATCH = 6
  ACTIVITY_REVIEW = 7
  ACTIVITY_PUBLISH = 8
  ACTIVITY_WORKFLOW = 9
  ACTIVITY_ANSWER = 10
  ACTIVITY_HANDLED = 11
  # ACTIVITY_LOGIN = 12
  # ACTIVITY_PROFILE = 13
  # ACTIVITY_COLLEAGUE_PROFILE = 14
  # ACTIVITY_GROUP = 15


  ACTIVITY_LABELS = {
    ACTIVITY_OTHER => 'other activity',
    ACTIVITY_EDIT => 'edit',
    ACTIVITY_COMMENT => 'comment',
    ACTIVITY_BOOKMARK => 'bookmark',
    ACTIVITY_ATTEND => 'attend',
    ACTIVITY_WATCH => 'watch',
    ACTIVITY_REVIEW => 'review',
    ACTIVITY_PUBLISH => 'publish',
    ACTIVITY_WORKFLOW => 'workflow',
    ACTIVITY_ANSWER => 'answer',
    ACTIVITY_HANDLED => 'handled'
    # ACTIVITY_LOGIN => 'login',
    # ACTIVITY_PROFILE => 'profile',
    # ACTIVITY_COLLEAGUE_PROFILE => 'colleague profile',
    # ACTIVITY_GROUP => 'group'
  }










end
