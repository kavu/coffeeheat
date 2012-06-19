all: coffeeheat.min.js coffeeheat.gmaps.min.js coffeeheat.openlayers.min.js

coffeeheat.js: src/main.coffee
	coffee -p -c src/main.coffee > coffeeheat.js

coffeeheat.min.js: coffeeheat.js
	uglifyjs coffeeheat.js > coffeeheat.min.js

coffeeheat.gmaps.js: src/heatmap-gmaps.js
	cp src/heatmap-gmaps.js coffeeheat.gmaps.js

coffeeheat.gmaps.min.js: coffeeheat.gmaps.js
	uglifyjs coffeeheat.gmaps.js > coffeeheat.gmaps.min.js

coffeeheat.openlayers.js: src/heatmap-openlayers.js
	cp src/heatmap-openlayers.js coffeeheat.openlayers.js

coffeeheat.openlayers.min.js: coffeeheat.openlayers.js
	uglifyjs coffeeheat.openlayers.js > coffeeheat.openlayers.min.js

clean:
	rm -f *.js *.min.js
