const ROUTES_ENDPOINT = 'https://routes.googleapis.com/directions/v2:computeRoutes';
const GEOCODE_ENDPOINT = 'https://maps.googleapis.com/maps/api/geocode/json';

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

exports.computeRoute = async (req, res) => {
    try {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        if (!apiKey) {
            return res.status(500).json({
                error: 'GOOGLE_MAPS_API_KEY is not configured on the backend.'
            });
        }

        const origin = toWaypoint(req.body.origin);
        const destination = toWaypoint(req.body.destination);
        const travelMode = req.body.travelMode || 'DRIVE';

        if (!origin || !destination) {
            return res.status(400).json({
                error: 'origin and destination latitude/longitude are required.'
            });
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
            polyline: route.polyline?.encodedPolyline || ''
        });
    } catch (error) {
        console.error('Error in navigationController.computeRoute:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.geocodeAddress = async (req, res) => {
    try {
        const apiKey = process.env.GOOGLE_MAPS_API_KEY;
        if (!apiKey) {
            return res.status(500).json({
                error: 'GOOGLE_MAPS_API_KEY is not configured on the backend.'
            });
        }

        const address = req.body.address?.toString().trim();
        if (!address) {
            return res.status(400).json({ error: 'address is required.' });
        }

        const url = new URL(GEOCODE_ENDPOINT);
        url.searchParams.set('address', address);
        url.searchParams.set('key', apiKey);

        const response = await fetch(url);
        const payload = await response.json().catch(() => ({}));
        if (!response.ok || payload.status !== 'OK') {
            return res.status(response.ok ? 404 : response.status).json({
                error: payload.error_message || payload.status || 'Could not geocode address.'
            });
        }

        const result = payload.results?.[0];
        const location = result?.geometry?.location;
        if (!location) {
            return res.status(404).json({ error: 'No location found for this address.' });
        }

        res.status(200).json({
            placeName: result.address_components?.[0]?.long_name || '',
            address: result.formatted_address || address,
            latitude: location.lat,
            longitude: location.lng
        });
    } catch (error) {
        console.error('Error in navigationController.geocodeAddress:', error);
        res.status(500).json({ error: error.message });
    }
};
