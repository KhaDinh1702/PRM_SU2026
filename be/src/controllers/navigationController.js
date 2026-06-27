const ROUTES_ENDPOINT = 'https://routes.googleapis.com/directions/v2:computeRoutes';
const GEOCODE_ENDPOINT = 'https://maps.googleapis.com/maps/api/geocode/json';
const PLACES_TEXT_SEARCH_ENDPOINT = 'https://places.googleapis.com/v1/places:searchText';
const NOMINATIM_SEARCH_ENDPOINT = 'https://nominatim.openstreetmap.org/search';
const NOMINATIM_REVERSE_ENDPOINT = 'https://nominatim.openstreetmap.org/reverse';
const OSRM_ROUTE_ENDPOINT = 'https://router.project-osrm.org/route/v1/driving';
const VIETNAM_BOUNDS = {
    low: { latitude: 8.18, longitude: 102.14 },
    high: { latitude: 23.39, longitude: 109.46 }
};
const APP_USER_AGENT = 'FlowMate-Student-Project/1.0';
const googleMapsEnabled = () => process.env.ENABLE_GOOGLE_MAPS === 'true';

const toWaypoint = (point) => {
    const latitude = Number(point?.latitude);
    const longitude = Number(point?.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
        return null;
    }
    return {
        location: {
            latLng: {
                latitude,
                longitude
            }
        }
    };
};

const textSearchVietnam = async (apiKey, textQuery) => {
    const response = await fetch(PLACES_TEXT_SEARCH_ENDPOINT, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location'
        },
        body: JSON.stringify({
            textQuery,
            maxResultCount: 1,
            languageCode: 'vi',
            includedRegionCodes: ['VN'],
            locationRestriction: {
                rectangle: VIETNAM_BOUNDS
            }
        })
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
        const message = payload.error?.message || 'Places Text Search failed.';
        const status = response.status >= 500 ? 502 : response.status;
        const error = new Error(message);
        error.status = status;
        throw error;
    }

    const place = payload.places?.[0];
    const location = place?.location;
    if (!location) return null;

    return {
        placeName: place.displayName?.text || '',
        address: place.formattedAddress || textQuery,
        latitude: location.latitude,
        longitude: location.longitude
    };
};

const searchOpenStreetMapVietnam = async (textQuery) => {
    const url = new URL(NOMINATIM_SEARCH_ENDPOINT);
    url.searchParams.set('format', 'jsonv2');
    url.searchParams.set('q', `${textQuery}, Vietnam`);
    url.searchParams.set('countrycodes', 'vn');
    url.searchParams.set('limit', '1');
    url.searchParams.set('addressdetails', '1');

    const response = await fetch(url, {
        headers: { 'User-Agent': APP_USER_AGENT }
    });
    const payload = await response.json().catch(() => []);
    const result = Array.isArray(payload) ? payload[0] : null;
    if (!response.ok || !result) return null;

    return {
        placeName: result.name || result.display_name?.split(',')[0] || textQuery,
        address: result.display_name || textQuery,
        latitude: Number(result.lat),
        longitude: Number(result.lon),
        provider: 'openstreetmap'
    };
};

const reverseOpenStreetMap = async (latitude, longitude) => {
    const url = new URL(NOMINATIM_REVERSE_ENDPOINT);
    url.searchParams.set('format', 'jsonv2');
    url.searchParams.set('lat', latitude.toString());
    url.searchParams.set('lon', longitude.toString());
    url.searchParams.set('zoom', '18');
    url.searchParams.set('addressdetails', '1');

    const response = await fetch(url, {
        headers: { 'User-Agent': APP_USER_AGENT }
    });
    const result = await response.json().catch(() => null);
    if (!response.ok || !result) return null;

    return {
        placeName: result.name || result.display_name?.split(',')[0] || 'Selected location',
        address: result.display_name || '',
        latitude,
        longitude,
        provider: 'openstreetmap'
    };
};

const computeOpenStreetMapRoute = async (origin, destination) => {
    const originLngLat = `${origin.location.latLng.longitude},${origin.location.latLng.latitude}`;
    const destinationLngLat = `${destination.location.latLng.longitude},${destination.location.latLng.latitude}`;
    const url = new URL(`${OSRM_ROUTE_ENDPOINT}/${originLngLat};${destinationLngLat}`);
    url.searchParams.set('overview', 'full');
    url.searchParams.set('geometries', 'polyline');
    url.searchParams.set('alternatives', 'false');
    url.searchParams.set('steps', 'false');

    const response = await fetch(url, {
        headers: { 'User-Agent': APP_USER_AGENT }
    });
    const payload = await response.json().catch(() => ({}));
    const route = payload.routes?.[0];
    if (!response.ok || !route) return null;

    return {
        distanceMeters: Math.round(route.distance || 0),
        duration: `${Math.round(route.duration || 0)}s`,
        polyline: route.geometry || '',
        provider: 'openstreetmap'
    };
};

exports.computeRoute = async (req, res) => {
    try {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        const origin = toWaypoint(req.body.origin);
        const destination = toWaypoint(req.body.destination);
        const travelMode = req.body.travelMode || 'DRIVE';

        if (!origin || !destination) {
            return res.status(400).json({
                error: 'origin and destination latitude/longitude are required.'
            });
        }

        if (!apiKey || !googleMapsEnabled()) {
            const fallbackRoute = await computeOpenStreetMapRoute(origin, destination);
            if (fallbackRoute) return res.status(200).json(fallbackRoute);
            return res.status(500).json({ error: 'No route provider is available.' });
        }

        const body = {
            origin,
            destination,
            travelMode,
            polylineQuality: 'HIGH_QUALITY'
        };
        if (travelMode === 'DRIVE') {
            body.routingPreference = 'TRAFFIC_AWARE';
        }

        const response = await fetch(ROUTES_ENDPOINT, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Goog-Api-Key': apiKey,
                'X-Goog-FieldMask': 'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline'
            },
            body: JSON.stringify(body)
        });

        const payload = await response.json().catch(() => ({}));
        if (!response.ok) {
            const fallbackRoute = await computeOpenStreetMapRoute(origin, destination);
            if (fallbackRoute) return res.status(200).json(fallbackRoute);
            return res.status(response.status).json({
                error: payload.error?.message || 'Could not compute route.',
                details: payload.error || payload
            });
        }

        const route = payload.routes?.[0];
        if (!route) {
            return res.status(404).json({ error: 'No route found for the selected destination.' });
        }

        res.status(200).json({
            distanceMeters: route.distanceMeters || 0,
            duration: route.duration || '0s',
            polyline: route.polyline?.encodedPolyline || '',
            provider: 'google'
        });
    } catch (error) {
        console.error('Error in navigationController.computeRoute:', error);
        try {
            const origin = toWaypoint(req.body.origin);
            const destination = toWaypoint(req.body.destination);
            if (origin && destination) {
                const fallbackRoute = await computeOpenStreetMapRoute(origin, destination);
                if (fallbackRoute) return res.status(200).json(fallbackRoute);
            }
        } catch (_) {}
        res.status(500).json({ error: error.message });
    }
};

exports.geocodeAddress = async (req, res) => {
    try {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        const address = req.body.address?.toString().trim();
        if (!address) {
            return res.status(400).json({ error: 'address is required.' });
        }

        if (apiKey && googleMapsEnabled()) {
            try {
                const place = await textSearchVietnam(apiKey, address);
                if (place) return res.status(200).json({ ...place, provider: 'google' });
            } catch (error) {
                console.warn('Google Places failed, falling back to OpenStreetMap:', error.message);
            }
        }

        if (apiKey && googleMapsEnabled()) {
            const url = new URL(GEOCODE_ENDPOINT);
            url.searchParams.set('address', address);
            url.searchParams.set('components', 'country:VN');
            url.searchParams.set('region', 'vn');
            url.searchParams.set('language', 'vi');
            url.searchParams.set('key', apiKey);

            const response = await fetch(url);
            const payload = await response.json().catch(() => ({}));
            if (response.ok && payload.status === 'OK') {
                const result = payload.results?.[0];
                const location = result?.geometry?.location;
                if (location) {
                    return res.status(200).json({
                        placeName: result.address_components?.[0]?.long_name || '',
                        address: result.formatted_address || address,
                        latitude: location.lat,
                        longitude: location.lng,
                        provider: 'google'
                    });
                }
            }
            console.warn('Google Geocoding failed, falling back to OpenStreetMap:', payload.error_message || payload.status);
        }

        const osmPlace = await searchOpenStreetMapVietnam(address);
        if (osmPlace) return res.status(200).json(osmPlace);

        res.status(404).json({ error: 'No location found for this address.' });
    } catch (error) {
        console.error('Error in navigationController.geocodeAddress:', error);
        res.status(error.status || 500).json({ error: error.message });
    }
};

exports.reverseGeocode = async (req, res) => {
    try {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        const latitude = Number(req.body.latitude);
        const longitude = Number(req.body.longitude);
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
            return res.status(400).json({
                error: 'latitude and longitude are required.'
            });
        }

        if (apiKey && googleMapsEnabled()) {
            const url = new URL(GEOCODE_ENDPOINT);
            url.searchParams.set('latlng', `${latitude},${longitude}`);
            url.searchParams.set('region', 'vn');
            url.searchParams.set('language', 'vi');
            url.searchParams.set('key', apiKey);

            const response = await fetch(url);
            const payload = await response.json().catch(() => ({}));
            if (response.ok && payload.status === 'OK') {
                const result = payload.results?.[0];
                return res.status(200).json({
                    placeName: result?.address_components?.[0]?.long_name || 'Selected location',
                    address: result?.formatted_address || '',
                    latitude,
                    longitude,
                    provider: 'google'
                });
            }
            console.warn('Google Reverse Geocoding failed, falling back to OpenStreetMap:', payload.error_message || payload.status);
        }

        const osmPlace = await reverseOpenStreetMap(latitude, longitude);
        if (osmPlace) return res.status(200).json(osmPlace);

        res.status(404).json({ error: 'Could not reverse geocode location.' });
    } catch (error) {
        console.error('Error in navigationController.reverseGeocode:', error);
        res.status(500).json({ error: error.message });
    }
};
