Shortly.Router = Backbone.Router.extend({

  initialize: function(options){
    this.$el = options.el;
  },

  routes: {
    "":       "index",
    "create": "create"
  },

  swapView: function(view){
    this.$el.html( view.render().el );
  },

  index: function(){
    var links = new Shortly.Links();
    var linksView = new Shortly.LinksView( {collection: links} );
    this.swapView(linksView);
  },

  create: function(){
    var linkCreateView = new Shortly.LinkCreateView();
    this.swapView(linkCreateView)
  }

});