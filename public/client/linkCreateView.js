Shortly.LinkCreateView = Backbone.View.extend({

  className: 'creator',

  template: _.template(' \
    <form> \
        <input class="text" type="text" name="url"> \
        <input type="submit" value="Shorten"> \
    </form> \
    <img class="spinner" src="/spiffygif_46x46.gif"> \
    <div class="message"></div>'
  ),

  events: {
    "submit": "shortenUrl"
  },

  render: function() {
    this.$el.html( this.template() );
    return this;
  },

  shortenUrl: function(e){
    e.preventDefault();
    var $form = this.$el.find('form .text');
    var link = new Shortly.Link( {url: $form.val()} )
    link.on('request', this.startSpinner, this);
    link.on('sync',    this.success,      this );
    link.on('error',   this.failure,      this );
    $form.val('');
    link.save();
  },

  success: function(link){
    this.stopSpinner();
    var view = new Shortly.LinkView( {model: link} );
    this.$el.find('.message').append(view.render().$el.hide().fadeIn());
  },

  failure: function(){
    this.stopSpinner();
    this.$el.find('.message').html("Please enter a valid URL").addClass('error');
  },

  startSpinner: function(){
    this.$el.find('img').show();
    this.$el.find('form input[type=submit]').attr('disabled', "true");
    this.$el.find('.message').html("").removeClass('error');
  },

  stopSpinner: function(){
    this.$el.find('img').fadeOut('fast');
    this.$el.find('form input[type=submit]').attr('disabled', null);
    this.$el.find('.message').html("").removeClass('error');
  }

});